provider "aws" {
  region = "eu-central-1"
}


resource "aws_instance" "s3-service-vm" {
  ami                    = data.aws_ami.amazon-linux.id
  instance_type          = "t2.micro"
  key_name               = "mk-rsa"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.default-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.s3-admin-profile.name
  user_data              = <<EOF
#!/bin/sh
cd /
yum install -y httpd
cd /var/www/html
echo -n "${local.site_content}" > index.html
aws s3 cp --acl public-read index.html s3://${aws_s3_bucket.netology-15-site.bucket}/
rm -f /etc/httpd/conf.d/welcome.conf
systemctl enable --now httpd
EOF
}

