variable "resource_group_name" {
  description = "리소스 그룹의 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "vm_name" {
  description = "가상 머신 이름"
  type        = string
}

variable "admin_username" {
  description = "VM 관리자 계정 이름"
  type        = string
}

variable "ssh_public_key_path" {
  description = "SSH 공개키 파일 경로 (Terraform 실행 위치 기준 상대 경로 또는 절대 경로)"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}