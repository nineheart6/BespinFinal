terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # 2025년 기준 최신 안정 버전 대역
    }
  }
}

provider "aws" {
  region = var.aws_region
}