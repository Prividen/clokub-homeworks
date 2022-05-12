resource "yandex_mdb_mysql_cluster" "netology-db-cluster" {
  name        = "netology-db-cluster"
  # Использовать окружение PRESTABLE
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.vpc-15.id
  version     = "8.0"

  resources {
    # платформу Intel Broadwell с производительностью 50% CPU
    resource_preset_id = "b1.medium"
    disk_type_id       = "network-ssd"
    # размером диска 20 Гб
    disk_size          = 20
  }

  maintenance_window {
    # Необходимо предусмотреть репликацию с произвольным временем технического обслуживания
    type = "ANYTIME"
  }

  backup_window_start {
    # Задать время начала резервного копирования - 23:59
    hours = 23
    minutes = 59
  }

  # Включить защиту кластера от непреднамеренного удаления
  deletion_protection = true

  database {
    name = local.db.name
  }

  user {
    # Создать БД с именем `netology_db` c логином и паролем
    name     = local.db.user
    password = local.db.password
    permission {
      database_name = local.db.name
      roles         = ["ALL"]
    }
  }

  # Разместить ноды кластера MySQL в разных подсетях
  dynamic "host" {
    for_each = local.networks
    content {
      zone = host.value.zone_name
      subnet_id = yandex_vpc_subnet.private[host.key].id
      name = "db-host-${host.key}"
    }
  }
}


output "db_cluster_hosts_fqdn" {
  value = yandex_mdb_mysql_cluster.netology-db-cluster.host.*.fqdn
}

output "db_cluster_master" {
  value = "c-${yandex_mdb_mysql_cluster.netology-db-cluster.id}.rw.mdb.yandexcloud.net"
}

output "db_creds" {
  value = "${local.db.name} -u ${local.db.user} -p'${local.db.password}'"
}
