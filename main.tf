provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  backend "s3" {}
  required_version = "~> 0.11"
}

locals {
  service_name   = "nginx-nlb-forwarder"
  container_port = 8080
}
