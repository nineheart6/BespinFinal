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
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

# 1. IAM Role 정의 (누가 이 역할을 쓸 수 있는가? -> EC2)
resource "aws_iam_role" "bastion_role" {
  name = "bastion_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# 2. Role에 권한(Policy) 붙이기
# 예시: S3 ReadOnly 권한 (원하는 권한으로 변경 가능)
resource "aws_iam_role_policy_attachment" "bastion_s3_readonly" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# [중요] 3. 인스턴스 프로파일 생성 (Role을 EC2에 전달하는 그릇)
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.pub_a.id
  key_name               = aws_key_pair.mykey.key_name
  user_data = (templatefile("${path.module}/userdata.tftpl", {
    server_port = var.server_port
    })
  )

  tags = {
    Name = "Bastion"
  }

  # 여기서 Role이 아니라 'Instance Profile'을 연결합니다.
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  depends_on = [aws_nat_gateway.pri_a]

}