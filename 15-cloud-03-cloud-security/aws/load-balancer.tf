# Create Load Balancer
#
resource "aws_lb" "web" {
  name               = "web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.default-sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "web-http" {
   name     = "web-http"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.vpc-15.id
}

resource "aws_lb_target_group_attachment" "web-http" {
  target_group_arn = aws_lb_target_group.web-http.arn
  target_id        = aws_instance.s3-service-vm.id
  port             = 80
}

resource "aws_lb_listener" "http-web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-http.arn
  }
}

resource "aws_lb_listener" "https-web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-http.arn
  }
}

