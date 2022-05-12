resource "yandex_kubernetes_cluster" "netology-cluster" {
  name        = "netology-cluster"
  network_id = yandex_vpc_network.vpc-15.id

  master {
    # Создать региональный мастер kubernetes с размещением нод в разных 3 подсетях
    regional {
      region = "ru-central1"

      dynamic location {
        for_each = local.networks
        content {
          zone    = yandex_vpc_subnet.public[location.key].zone
          subnet_id = yandex_vpc_subnet.public[location.key].id
        }
      }
    }

    version   = local.k8s.version
    public_ip = true
   }

  service_account_id      = yandex_iam_service_account.sa-15.id
  node_service_account_id = yandex_iam_service_account.sa-15.id
  depends_on = [
    yandex_vpc_network.vpc-15,
    yandex_vpc_subnet.public,
    yandex_iam_service_account.sa-15,
    yandex_resourcemanager_folder_iam_member.sa-editor,
    yandex_resourcemanager_folder_iam_member.sa-images-puller,
    yandex_kms_symmetric_key.k8s-key
  ]

  release_channel = "STABLE"

  # Добавить возможность шифрования ключом из KMS, созданного в предыдущем ДЗ
  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s-key.id
  }
}

# Создать группу узлов состояющую из 3 машин с автомасштабированием до 6
resource "yandex_kubernetes_node_group" "netology-cluster-nodegroup" {
  # in 3 different zones
  for_each = local.networks
  cluster_id  = yandex_kubernetes_cluster.netology-cluster.id
  name        = "netology-cluster-nodegroup-${each.key}"
  version     = local.k8s.version

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = [yandex_vpc_subnet.public[each.key].id]
    }

    resources {
      memory = local.k8s.node-resources.mem
      cores  = local.k8s.node-resources.cpu
    }

    boot_disk {
      type = "network-ssd-nonreplicated"
      size = 93
    }

    scheduling_policy {
      preemptible = true
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
    }
  }

  scale_policy {
    auto_scale {
      min = local.k8s.nodes-per-zone.min
      max = local.k8s.nodes-per-zone.max
      initial = local.k8s.nodes-per-zone.min
    }
  }

  allocation_policy {
    location {
      zone = each.value.zone_name
    }
  }
}

output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.netology-cluster.id
}

output "k8s_cluster_name" {
  value = yandex_kubernetes_cluster.netology-cluster.name
}

output "k8s_endpoint" {
  value = yandex_kubernetes_cluster.netology-cluster.master[0].external_v4_endpoint
}