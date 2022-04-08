provider "aws" {
  region = "eu-central-1"
}

locals {
  vpc_subnet = "10.10.0.0/16"
  public_subnet = "10.10.1.0/24"
  private_subnet = "10.10.2.0/24"
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
  # Разрешить в данной subnet присвоение public IP по-умолчанию.
  map_public_ip_on_launch = true
  tags = {
    Name = "vpc-15-public"
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

# Создать security group с разрешающими правилами на SSH и ICMP
resource "aws_security_group" "default-sg" {
  name = "vpc-15-default-sg"
  description = "Allow SSH and ICMP incoming traffic"
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



# Create test VMs
resource "aws_instance" "test-public-vm" {
  ami = data.aws_ami.alma8.id
  instance_type = "t2.micro"
  key_name = "mk-rsa"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.default-sg.id]
}


resource "aws_instance" "test-private-vm" {
  ami = data.aws_ami.alma8.id
  instance_type = "t2.micro"
  key_name = "mk-rsa"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.default-sg.id]
}

