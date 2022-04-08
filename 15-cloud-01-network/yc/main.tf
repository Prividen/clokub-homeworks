locals {
  zone = "ru-central1-a"
  nat_image_id = "fd80mrhj8fl2oe87o4e1"
  public_subnet = ["192.168.10.0/24"]
  private_subnet = ["192.168.20.0/24"]
  nat_gw = "192.168.10.254"
}

provider "yandex" {
  cloud_id = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone = local.zone
}

# AlmaLinux 8 image
data "yandex_compute_image" "alma8" {
  family = "almalinux-8"
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

# Создать в этой подсети NAT-инстанс,
resource "yandex_compute_instance" "nat-instance" {
  name = "nat-instance"
  hostname = "nat-instance"

  resources {
    cores = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # В качестве image_id использовать fd80mrhj8fl2oe87o4e1
      image_id = local.nat_image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    # присвоив ему адрес 192.168.10.254
    ip_address = local.nat_gw
    nat = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}


# Create test VMs

resource "yandex_compute_instance" "test-public-vm" {
  name = "test-public-vm"
  hostname = "test-public-vm"

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
    subnet_id = yandex_vpc_subnet.public.id
    nat = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}


resource "yandex_compute_instance" "test-private-vm" {
  name = "test-private-vm"
  hostname = "test-private-vm"

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
    subnet_id = yandex_vpc_subnet.private.id
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}
