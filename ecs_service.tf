resource "aws_ecs_service" "service" {
  name            = "${local.service_name}"
  cluster         = "${var.ecs_service_arn}"
  task_definition = "${aws_ecs_task_definition.task.arn}"

  desired_count                      = "3"
  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"
  health_check_grace_period_seconds  = "0"

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.ami-id != 'ami-fake'"
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.tg_for_nlb.arn}"
    container_name   = "${local.service_name}"
    container_port   = "${local.container_port}"
  }

  network_configuration {
    subnets = ["${var.subnet_ids}"]
    security_groups = ["${aws_security_group.eip_to_ecs.id}"]
  }
}

resource "aws_ecs_task_definition" "task" {
  family                = "${local.service_name}"
  container_definitions = "${data.template_file.ecs_task_container_definitions.rendered}"
  task_role_arn         = "${aws_iam_role.ecs_task.arn}"
  # each task gets its own net interface
  network_mode          = "awsvpc"
}

resource "aws_security_group" "eip_to_ecs" {
  name        = "${local.service_name}-${var.environment}-allow-ecs-access"
  description = "allow connetions between eips and ecs tasks"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${local.container_port}"
    to_port   = "${local.container_port}"
    protocol  = "tcp"

    # these apis are available later, might require running apply twice :<
    cidr_blocks = [
      "${aws_eip.lb1.private_ip}/32",
      "${aws_eip.lb2.private_ip}/32",
    ]
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.environment}-${local.service_name}-task"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task.json}"
}

data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "template_file" "ecs_task_container_definitions" {
  template = "${file("${path.module}/container-definition.json")}"

  vars {
    container_name = "${local.service_name}"

    image          = "${var.docker_image}"
    version        = "${var.docker_image_version}"
    cpu            = "${var.ecs_cpu}"
    memory         = "${var.ecs_memory}"
    container_port = "${local.container_port}"
    api_endpoint   = "${var.target_service_domain_name}:443"
  }
}
