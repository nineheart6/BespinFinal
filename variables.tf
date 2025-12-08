#### Network - VPC ####


#### Compute - EC2 ####

variable "image_id" {
  description = "The id of the server image"
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

variable "web_security_group_name" {
  description = "The name of the web security group"
  type        = string
}

variable "my_ip" {
  description = "The ip address of my computer"
  type        = string
}

#### Compute - ALB ####

variable "alb_security_group_name" {
  description = "The name of the alb security group"
  type        = string
}

variable "alb_name" {
  description = "The name of the alb"
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