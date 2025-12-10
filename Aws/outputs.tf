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

# Tunnel 1 정보
output "vpn_tunnel1_address" {
  description = "The public IP address of the first VPN tunnel"
  value       = aws_vpn_connection.main.tunnel1_address
}

output "vpn_tunnel1_preshared_key" {
  description = "The preshared key of the first VPN tunnel"
  value       = aws_vpn_connection.main.tunnel1_preshared_key
  sensitive   = true # 민감 정보이므로 콘솔에 바로 노출되지 않음
}

# Tunnel 2 정보 (AWS VPN은 이중화를 위해 항상 2개의 터널을 제공함)
/* output "vpn_tunnel2_address" {
  description = "The public IP address of the second VPN tunnel"
  value       = aws_vpn_connection.main.tunnel2_address
}

output "vpn_tunnel2_preshared_key" {
  description = "The preshared key of the second VPN tunnel"
  value       = aws_vpn_connection.main.tunnel2_preshared_key
  #sensitive   = true
} */