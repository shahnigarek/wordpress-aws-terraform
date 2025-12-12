output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mariadb.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.mariadb.address
}
