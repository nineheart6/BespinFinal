output "server_port" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.tf-db.address
}

output "db_connect_command" {
  description = "Run this command to connect to the database immediately"
  # 비밀번호에 특수문자가 있을 수 있으므로 작은따옴표('')로 감싸는 것이 안전합니다.
  # -p와 비밀번호 사이에는 공백이 없어야 합니다.
  value = "mysql -h ${aws_db_instance.tf-db.address} -u ${var.db_username} -p'${var.db_password}' ${var.db_name}"
}

output "server_ip" {
  description = "ip of ec2"
  value       = aws_instance.bastion.public_ip
}