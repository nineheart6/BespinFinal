output "db_server_endpoint" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.tf-db.address
}

output "alb_domain_name" {
  description = "The domain name of the load balancer"
  value       = aws_lb.alb.dns_name
}