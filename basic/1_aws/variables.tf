#### Network - VPC ####


#### Compute - EC2 ####

variable "key_path" {
  description = "Public Key 파일이 위치한 로컬 디렉터리 경로"
  type        = string
}

variable "instance_type" {
  description = "The type of the server"
  type        = string
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

variable "bastion_security_group_name" {
  description = "The name of the bastion security group"
  type        = string
}

variable "my_ip" {
  description = "The ip address of my computer"
  type        = string
}

#### Database - RDS ####

variable "db_security_group_name" {
  description = "The name of the db security group"
  type        = string
}

#보안을 위해 분리
variable "db_username" {
  description = "The username of the RDS"
  type        = string
}

variable "db_password" {
  description = "The password of the RDS"
  type        = string
}

variable "db_name" {
  description = "The password of the RDS"
  type        = string
}
