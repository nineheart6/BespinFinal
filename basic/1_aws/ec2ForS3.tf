#rds 덤프를 만들고 s3에 저장할 ec2 생성
#
#
# ---------------------------------------------------------
# 1. IAM Role & Policy (최소 권한: S3 업로드 전용)
# ---------------------------------------------------------

# 전용 역할 생성
resource "aws_iam_role" "db_worker_role" {
  name = "db_worker_role_minimal"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 최소 권한 정책 정의 (S3 업로드만 가능)
resource "aws_iam_policy" "db_backup_policy" {
  name        = "db_backup_s3_minimal_policy"
  description = "Allow PutObject to S3 for DB backups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",       # 파일 업로드
          "s3:GetBucketLocation",
          "s3:ListBucket"       # 버킷 조회
        ]
        # [보안 강화 포인트] 실제 운영 시에는 "*" 대신 특정 버킷 ARN으로 제한하세요.
        # 예: "arn:aws:s3:::my-backup-bucket/*"
        Resource = "*"
      }
    ]
  })
}

# 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "db_worker_attach" {
  role       = aws_iam_role.db_worker_role.name
  policy_arn = aws_iam_policy.db_backup_policy.arn
}

# 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "db_worker_profile" {
  name = "db_worker_profile_minimal"
  role = aws_iam_role.db_worker_role.name
}

# ---------------------------------------------------------
# 2. Security Group (최소 권한: 필요한 포트만 Open)
# ---------------------------------------------------------

resource "aws_security_group" "private_db_worker" {
  name        = "private-db-worker-sg"
  description = "Minimal security group for DB worker"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "private-db-worker-sg"
  }
}

# Ingress: Bastion에서 오는 SSH(22)만 허용
resource "aws_vpc_security_group_ingress_rule" "worker_ssh_from_bastion" {
  security_group_id            = aws_security_group.private_db_worker.id
  description                  = "SSH from Bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_server" {
  security_group_id = aws_security_group.private_db_worker.id
  description       = "outbound_all"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}


# ---------------------------------------------------------
# 3. EC2 Instance
# ---------------------------------------------------------

resource "aws_instance" "db_worker" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.mykey.key_name
  subnet_id     = aws_subnet.db_pri_a.id

  # 위에서 만든 최소 권한 보안 그룹 적용
  vpc_security_group_ids = [aws_security_group.private_db_worker.id]

  # [변경] Admin 권한 대신 새로 만든 최소 권한 프로파일 적용
  iam_instance_profile = aws_iam_instance_profile.db_worker_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install mariadb105 -y
              EOF

  tags = {
    Name = "DB-Worker-Minimal"
  }

  depends_on = [aws_nat_gateway.pri_a]
}