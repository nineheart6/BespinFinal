output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

# 접속 편의를 위해 개인키 경로를 절대 경로로 조합하여 출력합니다.
output "ssh_command" {
  value = "ssh -i /home/ubuntu/task/BespinFinal/keys/mykey ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

# DB 접속 정보 출력
output "mysql_server_host" {
  value       = azurerm_mysql_flexible_server.mysql.fqdn
  description = "MySQL 서버 접속 주소 (Bastion에서만 접속 가능)"
}

output "mysql_admin_username" {
  value = var.db_admin_username
}

output "mysql_suffix_name" {
  value = azurerm_mysql_flexible_server.mysql.name
}

# # 중요: 생성된 DB 비밀번호 출력 (민감 정보이므로 sensitive=true)
# output "mysql_admin_password" {
#   value     = random_password.db_password.result
#   # 이렇게 설정하면 output에서 따로 입력해야 보인다.
#   # 빠른 테스트를 위해 제거
#   #sensitive = true
# }