#aws에 로컬에서 생성한 키 등록
resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = file("${path.module}/keys/mykey.pub")
}

#### Compute - EC2 ####
#최신의 amazon linux 2023 가져오기
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    #al2023-ami-2023.9.20251117.1-kernel-6.1-x86_64
    values = ["al2023-ami-2023.*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
#web security group 다른 보안그룹에 대한 참조 시 충돌 방지를 위한 방식
resource "aws_security_group" "bastion" {
  name        = var.bastion_security_group_name
  description = "Allow HTTP inbound traffic from alb"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = var.bastion_security_group_name
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from VPC"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip
}

resource "aws_vpc_security_group_egress_rule" "allow_all_web" {
  security_group_id = aws_security_group.bastion.id
  description       = "outbound_all"
  #0 사용 금지
  from_port   = -1
  to_port     = -1
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [ aws_security_group.bastion ]
  user_data = base64encode(templatefile("${path.module}/userdata.tftpl", {
    server_port = var.server_port
    db_username = var.db_username
    db_password = var.db_password
    db_name     = var.db_name
    db_endpoint = aws_db_instance.tf-db.address
    })
  )
  depends_on = [aws_nat_gateway.pri_a, aws_db_instance.tf-db]
  tags = {
    Name = "Bastion"
  }

}