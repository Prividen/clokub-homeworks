resource "aws_route53_zone" "aws-zone" {
  name = local.dns_zone_name
}

resource "aws_route53_record" "elk" {
  zone_id = aws_route53_zone.aws-zone.zone_id
  name    = "elk.${local.dns_zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.web.dns_name]
}
