provider "aws" {
  region = "eu-central-1"
}

locals {
  vpc_subnet = "10.10.0.0/16"
  public_subnet = "10.10.1.0/24"
  public2_subnet = "10.10.10.0/24"
  private_subnet = "10.10.2.0/24"
  pict_name = "elk.jpg"
}

# AlmaLinux 8 image
data "aws_ami" "alma8" {
  most_recent = true

  filter {
    name = "name"
    values = ["AlmaLinux OS 8*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["764336703387"]
}


# Создать VPC. Cоздать пустую VPC с подсетью 10.10.0.0/16.
resource "aws_vpc" "vpc-15" {
  cidr_block = local.vpc_subnet
  tags = {
    Name = "vpc-15"
  }
}


# Создать в vpc subnet с названием public, сетью 10.10.1.0/24
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.vpc-15.id
  cidr_block = local.public_subnet
  availability_zone = "eu-central-1a"
  # Разрешить в данной subnet присвоение public IP по-умолчанию.
  map_public_ip_on_launch = true
  tags = {
    Name = "vpc-15-public"
  }
}

# Yet another public subnet for LoadBalancer
resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.vpc-15.id
  cidr_block = local.public2_subnet
  availability_zone = "eu-central-1b"
  # Разрешить в данной subnet присвоение public IP по-умолчанию.
  map_public_ip_on_launch = true
  tags = {
    Name = "vpc-15-public2"
  }
}


# Создать в vpc subnet с названием private, сетью 10.10.2.0/24
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.vpc-15.id
  cidr_block = local.private_subnet
  tags = {
    Name = "vpc-15-private"
  }
}

# Создать Internet gateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.vpc-15.id
  tags = {
    Name = "vpc-15-internet-gw"
  }
}

# Создать отдельную таблицу маршрутизации
resource "aws_route_table" "private-routes" {
  vpc_id = aws_vpc.vpc-15.id
  tags = {
    Name = "vpc-15-private-routes"
  }
}

# и привязать ее к private-подсети
resource "aws_route_table_association" "private-routes" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private-routes.id
}

# Добавить Route, направляющий весь исходящий трафик private сети в NAT.
resource "aws_route" "default-route-via-nat" {
  route_table_id = aws_route_table.private-routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat-gw.id
}


# Добавить в таблицу маршрутизации маршрут, направляющий весь исходящий трафик в Internet gateway.
resource "aws_route" "default-route-via-internet-gw" {
  route_table_id = aws_vpc.vpc-15.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet-gw.id
}

# Создать security group с разрешающими правилами на SSH и ICMP и HTTP
resource "aws_security_group" "default-sg" {
  name = "vpc-15-default-sg"
  description = "Allow HTTP, SSH and ICMP incoming traffic"
  vpc_id = aws_vpc.vpc-15.id
}

resource "aws_security_group_rule" "incoming-ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default-sg.id
}

resource "aws_security_group_rule" "incoming-http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default-sg.id
}

resource "aws_security_group_rule" "incoming-icmp" {
  type = "ingress"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default-sg.id
}

resource "aws_security_group_rule" "permissive-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default-sg.id
}



# Добавить NAT gateway в public subnet.
resource "aws_eip" "eip-for-nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip-for-nat.id
  subnet_id = aws_subnet.public.id
  depends_on = [aws_internet_gateway.internet-gw]
  tags = {
    Name = "vpc-15-public-nat-gw"
  }
}


# Create S3 bucket and upload a picture

resource "aws_s3_bucket" "netology-15-02" {
  bucket = "netology-15-02"

  tags = {
    Name        = "netology-15-02"
  }
}

resource "aws_s3_bucket_acl" "netology-15-02-acl" {
  bucket = aws_s3_bucket.netology-15-02.id
  acl = "public-read"
}


resource "aws_s3_object" "elk-picture" {
  bucket = aws_s3_bucket.netology-15-02.bucket
  key = local.pict_name
  content_type = "image/jpeg"
  source = "../${local.pict_name}"
  acl = "public-read"
}



# Create Launch Configuration and Autoscaling Group

resource "aws_launch_configuration" "web_config" {
  name          = "web_config"
  image_id      = data.aws_ami.alma8.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.default-sg.id]
  key_name = "mk-rsa"
  user_data = <<EOF
#!/bin/sh
PICURL="https://${aws_s3_bucket.netology-15-02.bucket_regional_domain_name}/${aws_s3_object.elk-picture.key}"
dnf install -y httpd
rm -f /etc/httpd/conf.d/welcome.conf
systemctl enable --now httpd
cd /var/www/html
echo "<html><body><h1>ELK</h1><p>This is elk:</p><img src='$PICURL'>" > index.html
echo "<p>This elk lives at $(hostname -s)</p></body></html>" >> index.html
EOF
}


resource "aws_autoscaling_group" "web" {
  name                 = "web"
  launch_configuration = aws_launch_configuration.web_config.name
  min_size             = 3
  max_size             = 3
  desired_capacity     = 3
  vpc_zone_identifier  = [aws_subnet.public.id]

  lifecycle {
    create_before_destroy = true
  }
}






# Create Load Balancer

resource "aws_lb" "web" {
  name               = "web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.default-sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "web-tg" {
   name     = "web-tg"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.vpc-15.id
}

resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  lb_target_group_arn   = aws_lb_target_group.web-tg.arn
}


resource "aws_lb_listener" "http-web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }
}

