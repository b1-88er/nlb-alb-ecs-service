output "elastic_ip" {
  value = [
    aws_eip.lb1.public_ip,
    aws_eip.lb2.public_ip,
  ]
}

output "static_ips_dns" {
  value = aws_route53_record.domain_to_eips.name
}

