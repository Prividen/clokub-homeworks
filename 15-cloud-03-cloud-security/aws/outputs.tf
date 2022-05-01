output "LB_addr" {
  value = aws_lb.web.dns_name
}

output "vm_public_ip" {
  description = "S3 service VM public IP"
  value = aws_instance.s3-service-vm.public_ip
}

output "encrypted_bucket_link" {
  value = "https://${aws_s3_bucket.netology-15-encrypted.bucket_domain_name}/${local.pict_name}"
}

output "site_bucket_link" {
  value = "https://${aws_s3_bucket.netology-15-site.bucket_domain_name}/${local.pict_name}"
}

output "static_website_link" {
  value = "${aws_s3_bucket_website_configuration.s3-site.website_endpoint}"
}

output "site_dns_record" {
  value = aws_route53_record.elk.name
}

output "zone_ns_servers" {
  value = aws_route53_zone.aws-zone.name_servers
}
