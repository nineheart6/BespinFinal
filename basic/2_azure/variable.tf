variable "aws_access_key" {
  description = "AWS IAM User Access Key (S3 Read 권한 필요)"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS IAM User Secret Key"
  type        = string
  sensitive   = true
}