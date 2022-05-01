locals {
  vpc_subnet     = "10.10.0.0/16"
  public_subnet  = "10.10.1.0/24"
  public2_subnet = "10.10.10.0/24"
  private_subnet = "10.10.2.0/24"
  pict_name      = "elk.jpg"
  site_pic_url   = "https://${aws_s3_bucket.netology-15-site.bucket_regional_domain_name}/${local.pict_name}"
  site_content   = <<EOT
<html><body><h1>ELK</h1><p>This is elk:</p>
<a href='${local.site_pic_url}'><img src='${local.site_pic_url}' width='15%'></a>
<p>This elk lives at object storage</p></body></html>
EOT
  cert_arn       = "arn:aws:acm:eu-central-1:548816444059:certificate/5c23ac08-fb73-4d84-aa37-f3f35688e85f"
  dns_zone_name  = "aws.complife.ru"
}



data "aws_ami" "amazon-linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}
