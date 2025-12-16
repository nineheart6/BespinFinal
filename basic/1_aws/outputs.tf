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

# 1. 로컬 -> Bastion 접속 명령어
output "cmd_1_ssh_to_bastion" {
  value       = "ssh -i ${var.key_path}/mykey ec2-user@${aws_instance.bastion.public_ip}"
  description = "로컬 터미널에서 Bastion Host로 접속하는 명령어입니다."
}

# 2. 로컬 -> Bastion으로 프라이빗 키 전송 명령어 (scp)
# Bastion 안에서 ssh -i를 쓰려면 키 파일이 그 안에 있어야 하니까요.
output "cmd_2_upload_key_to_bastion" {
  value       = "scp -i ${var.key_path}/mykey ${var.key_path}/mykey ec2-user@${aws_instance.bastion.public_ip}:/home/ec2-user/mykey"
  description = "로컬의 프라이빗 키를 Bastion Host 내부로 복사하는 명령어입니다."
}

# 3. Bastion -> Private DB Worker 접속 명령어
output "cmd_3_ssh_from_bastion_to_worker" {
  value       = "ssh -i mykey ec2-user@${aws_instance.db_worker.private_ip}"
  description = "Bastion 내부에서 Private DB Worker로 접속하는 명령어입니다. (키 전송 후 사용)"
}