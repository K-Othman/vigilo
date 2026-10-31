# --- Application Load Balancer (internet-facing, in the public subnets) ---
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  # Off on purpose: the stack is destroyed nightly to save cost
  enable_deletion_protection = false

  tags = {
    Name = "${var.name}-alb"
  }
}

# --- Target group: web tasks on port 3000, registered by ECS ---
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-web-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # Give in-flight requests 30s to finish when a task is replaced (default is 300s)
  deregistration_delay = 30

  tags = {
    Name = "${var.name}-web-tg"
  }
}

# --- Port 80: redirect everything to HTTPS ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# --- Port 443: terminate TLS and forward to the web tasks ---
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}