output "website_url" {
  value = "http://failover.${var.domain_name}"
}

output "server_ips" {
  value = aws_instance.web[*].public_ip
}