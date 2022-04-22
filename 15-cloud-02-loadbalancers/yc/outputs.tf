output "LAMP_nodes" {
  value = {
    for k, v in yandex_compute_instance_group.LAMP.instances:
        "${v.fqdn}" => "${v.network_interface.0.nat_ip_address}"
  }
}

output "LB_addr" {
  value = yandex_lb_network_load_balancer.lamp.listener.*.external_address_spec[*].*.address
}

output "ALB_addr" {
  value = yandex_alb_load_balancer.lamp.listener[*].endpoint[*].address[*].external_ipv4_address[*].address
}


