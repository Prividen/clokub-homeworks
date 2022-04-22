locals {
  zone = "ru-central1-a"
  lamp_image_id = "fd827b91d99psvq5fjit"
  public_subnet = ["192.168.10.0/24"]
  private_subnet = ["192.168.20.0/24"]
  nat_gw = "192.168.10.254"
}

provider "yandex" {
  cloud_id = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone = local.zone
}

# Создать VPC.
resource "yandex_vpc_network" "vpc-15" {
  name = "vpc-netology-15"
}

# Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс
resource "yandex_vpc_route_table" "via-nat" {
  network_id = yandex_vpc_network.vpc-15.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address = local.nat_gw
  }
}

# Создать в vpc subnet с названием public, сетью 192.168.10.0/24.
resource "yandex_vpc_subnet" "public" {
  v4_cidr_blocks = local.public_subnet
  zone = local.zone
  network_id = yandex_vpc_network.vpc-15.id
}

# Создать в vpc subnet с названием private, сетью 192.168.20.0/24.
resource "yandex_vpc_subnet" "private" {
  v4_cidr_blocks = local.private_subnet
  zone = local.zone
  network_id = yandex_vpc_network.vpc-15.id
  route_table_id = yandex_vpc_route_table.via-nat.id
}



# create service account with key and role assigment

resource "yandex_iam_service_account" "sa-15" {
  name      = "sa-15-02"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = yandex_iam_service_account.sa-15.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-15.id}"
  depends_on = [yandex_iam_service_account.sa-15]
}


resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa-15.id
  description        = "static access key for object storage"
  depends_on = [yandex_iam_service_account.sa-15]
}


# Create storage bucket with a picture

resource "yandex_storage_bucket" "netology-15-02" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  depends_on = [yandex_iam_service_account_static_access_key.sa-static-key]
  bucket = "netology-15-02"
  acl = "public-read"
}

resource "yandex_storage_object"  "elk" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  depends_on = [yandex_iam_service_account_static_access_key.sa-static-key]
  bucket = yandex_storage_bucket.netology-15-02.bucket
  key = "elk.jpg"
  content_type = "image/jpeg"
  source = "../elk.jpg"
  acl = "public-read"
}



# Create VM instance group

resource "yandex_compute_instance_group" "LAMP" {
  name               = "lamp"
  folder_id          = yandex_iam_service_account.sa-15.folder_id
  service_account_id = yandex_iam_service_account.sa-15.id
  depends_on = [yandex_resourcemanager_folder_iam_member.sa-editor]

  instance_template {
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = local.lamp_image_id
      }
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat = true
    }

    metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
    user-data = <<EOF
#!/bin/sh
PICURL="https://storage.yandexcloud.net/${yandex_storage_bucket.netology-15-02.bucket}/${yandex_storage_object.elk.key}"
cd /var/www/html
echo "<html><body><h1>ELK</h1><p>This is elk:</p><img src='$PICURL'>" > index.html
echo "<p>This elk lives at $(hostname -s)</p></body></html>" >> index.html
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [local.zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion = 0
  }

  health_check {
    interval = 10
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 6
    http_options {
      port = 80
      path = "/"
    }
  }

}


# Create L4 Load Balancer

resource "yandex_lb_target_group" "lamp" {
  name      = "lamp"

  dynamic "target" {
    for_each = yandex_compute_instance_group.LAMP.instances
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}


resource "yandex_lb_network_load_balancer" "lamp" {
  name = "lamp-load-balancer"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lamp.id

    healthcheck {
      name = "http"
      timeout = 1
      healthy_threshold = 3
      unhealthy_threshold = 4
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}




# Create L7 Application Load Balancer

resource "yandex_alb_target_group" "lamp" {
  name      = "lamp"

  dynamic "target" {
    for_each = yandex_compute_instance_group.LAMP.instances
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      ip_address   = target.value.network_interface.0.ip_address
    }
  }
}


resource "yandex_alb_backend_group" "lamp" {
  name      = "lamp-backend"

  http_backend {
    name = "http-lamp-backend"
    weight = 1
    port = 80
    target_group_ids = [yandex_alb_target_group.lamp.id]
    healthcheck {
      timeout = "1s"
      interval = "2s"
      healthy_threshold = 3
      unhealthy_threshold = 4
      http_healthcheck {
        host = "alb-health-check"
        path  = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "lamp" {
  name      = "http-lamp-router"
}

resource "yandex_alb_virtual_host" "lamp-test-host" {
  name      = "lamp-test-host"
  http_router_id = yandex_alb_http_router.lamp.id
  route {
    name = "lamp-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.lamp.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "lamp" {
  name        = "lamp-app-load-balancer"

  network_id  = yandex_vpc_network.vpc-15.id

  allocation_policy {
    location {
      zone_id   = yandex_vpc_subnet.public.zone
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "lamp-http-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.lamp.id
      }
    }
  }
}


