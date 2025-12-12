#DB-SG
resource "aws_security_group" "db" {
  name        = var.db_security_group_name
  description = "Allow MySQL inbound traffic"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = var.db_security_group_name
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mariadb" {
  security_group_id            = aws_security_group.db.id
  description                  = "DBport from web"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_azuredb" {
  security_group_id            = aws_security_group.db.id
  description                  = "DBport for azure private"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  cidr_ipv4 = var.azure_cidr
}


resource "aws_vpc_security_group_egress_rule" "allow_all_db" {
  security_group_id = aws_security_group.db.id
  description       = "outbound_all"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "tf-db" {
  name       = "tf-db subnet group"
  subnet_ids = [aws_subnet.db_pri_a.id, aws_subnet.db_pri_c.id]

  tags = {
    Name = "tf-db subnet group"
  }
}



# 1. 파라미터 그룹 생성 (여기서 binlog_format을 설정)
resource "aws_db_parameter_group" "seoul" {
  name   = "tf-db-mysql-params"
  family = "mysql8.0"  # 사용하는 DB 엔진 버전과 맞춰야 합니다 (8.0)

  # 1. Binlog 형식을 ROW로 설정
  parameter {
    name  = "binlog_format"
    value = "ROW"
    apply_method = "pending-reboot" # 재부팅 적용
  }

  # 2. GTID 모드 활성화 (추가됨)
  parameter {
    name         = "gtid-mode"
    value        = "ON"
    apply_method = "pending-reboot" # 재부팅 적용
  }

  # 3. GTID 일관성 강제 (필수 추가!)
  # gtid_mode = ON을 위해서는 이 값이 반드시 ON이어야 합니다.
  parameter {
    name         = "enforce_gtid_consistency"
    value        = "ON"
    apply_method = "pending-reboot" # 재부팅 적용
  }
}

# 2. DB 인스턴스 설정
resource "aws_db_instance" "tf-db" {
  identifier            = "tf-db"
  allocated_storage     = 10
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  #multi_az               = true #이중화
  skip_final_snapshot   = true
  
  # 1. 위에서 만든 파라미터 그룹 연결
  parameter_group_name  = aws_db_parameter_group.seoul.name

  # 2. 백업 보존 기간 설정 (필수!)
  # 이 값이 0이면 바이너리 로그가 활성화되지 않아 복제가 불가능합니다.
  # 최소 1일 이상 설정해야 합니다.
  backup_retention_period = 1 

  db_subnet_group_name   = aws_db_subnet_group.tf-db.name
  vpc_security_group_ids = [aws_security_group.db.id]
}