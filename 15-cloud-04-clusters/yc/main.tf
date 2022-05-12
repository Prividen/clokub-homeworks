locals {
  networks = {
    a = {
      zone_name = "ru-central1-a"
      public_subnet = ["192.168.10.0/24"]
      private_subnet = ["192.168.20.0/24"]
    }
    b = {
      zone_name = "ru-central1-b"
      public_subnet = ["192.168.11.0/24"]
      private_subnet = ["192.168.21.0/24"]
    }
    c = {
      zone_name = "ru-central1-c"
      public_subnet = ["192.168.12.0/24"]
      private_subnet = ["192.168.22.0/24"]
    }
  }

  default_zone = local.networks.a.zone_name

  nat_gw = "192.168.10.254"
  nat_image_id = "fd80mrhj8fl2oe87o4e1"
  lamp_image_id = "fd827b91d99psvq5fjit"

  db = {
    name     = "netology_db"
    user     = "db_admin"
    password = "AdmIn_pa$sw0rd"
  }

  k8s = {
    version = "1.21"
    node-resources = {
      cpu = 2
      mem = 2
    }
    # as per placing node-groups in all 3 zones it give us: 1x3 min, 2x3 max
    nodes-per-zone = {
      min = 1
      max = 2
    }
  }
}

provider "yandex" {
  cloud_id = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone = local.default_zone
}

# AlmaLinux 8 image
data "yandex_compute_image" "alma8" {
  family = "almalinux-8"
}


resource "yandex_vpc_network" "vpc-15" {
  name = "vpc-netology-15"
}

# Public subnets in 3 zones
resource "yandex_vpc_subnet" "public" {
  for_each = local.networks
  v4_cidr_blocks = each.value.public_subnet
  zone = each.value.zone_name
  network_id = yandex_vpc_network.vpc-15.id
}


# Private subnets in 3 zones
resource "yandex_vpc_subnet" "private" {
  for_each = local.networks
  v4_cidr_blocks = each.value.private_subnet
  zone = each.value.zone_name
  network_id = yandex_vpc_network.vpc-15.id
}


# VM for testing database connection
resource "yandex_compute_instance" "test-vm" {
  name = "test-vm"
  hostname = "test-vm"

  resources {
    cores = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.alma8.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public["a"].id
    nat = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
    user-data = <<EOF
#!/bin/sh
dnf install -y mysql
EOF
  }
}

output "test_vm_ip" {
  description = "Test public IP"
  value = yandex_compute_instance.test-vm.network_interface.0.nat_ip_address
}
