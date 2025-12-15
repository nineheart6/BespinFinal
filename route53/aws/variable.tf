variable "aws_region" {
  description = "AWS 리전"
  default     = "ap-northeast-2" # 서울 리전
}

variable "domain_name" {
  description = "Route 53에 등록된 도메인 이름 (예: example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID"
  type        = string
}

variable "key_path" {
  description = "Public Key 파일이 위치한 로컬 디렉터리 경로"
  type        = string
}