variable "vpc_id" {}
variable "aws_region" {}
variable "environment" {}

variable "hosted_zone_id" {}
variable "domain_name" {}
variable "target_service_domain_name" {}
variable "lb_subnet_ids" {}

variable "ecs_subnet_ids" {}
variable "ecs_cluster_arn" {}
variable "ecs_memory" {}
variable "ecs_cpu" {}
variable "docker_image" {}
variable "docker_image_version" {}
