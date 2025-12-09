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