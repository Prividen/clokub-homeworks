output "test_public_ip" {
  description = "Test public IP"
  value = aws_instance.test-public-vm.public_ip
}

output "test_private_ip" {
  description = "Test private IP"
  value = aws_instance.test-private-vm.private_ip
}

output "public_nat_ip" {
  description = "Public NAT IP"
  value = aws_nat_gateway.nat-gw.public_ip
}
