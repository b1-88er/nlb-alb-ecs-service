# dont use count due to the bug: https://github.com/hashicorp/terraform/issues/4944
resource "aws_eip" "lb1" { vpc=true }
resource "aws_eip" "lb2" { vpc=true }

resource "aws_lb" "nlb" {
  name         = "${var.environment}-${local.service_name}"
  internal     = false
  idle_timeout = "60"

  load_balancer_type         = "network"
  enable_deletion_protection = false

  subnet_mapping = [
    {
      subnet_id = "${var.lb_subnet_ids[0]}",
      allocation_id = "${aws_eip.lb1.id}"
    },
    {
      subnet_id = "${var.lb_subnet_ids[1]}",
      allocation_id = "${aws_eip.lb2.id}"
    },
  ]

  enable_cross_zone_load_balancing = true
  ip_address_type                  = "ipv4"
}

resource "aws_route53_record" "domain_to_eips" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [
    "${aws_eip.lb1.public_ip}",
    "${aws_eip.lb2.public_ip}",
  ]
}

# Look up SSL certs issued by ACM
data "aws_acm_certificate" "cert" {
  domain   = "*.${var.domain_name}"
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "nlb_listener" {

  load_balancer_arn = "${module.nlb.nlb_arn}"
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${data.aws_acm_certificate.cert.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg_for_nlb.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg_for_nlb" {
  name        = "${var.environment}-${local.service_name}-tg-for-nlb"
  protocol    = "TCP"
  port        = "${local.container_port}"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    port = "${local.container_port}"
    interval = 10
  }

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

