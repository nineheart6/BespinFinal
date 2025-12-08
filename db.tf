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
  referenced_security_group_id = aws_security_group.web.id
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
  subnet_ids = [aws_subnet.pri_a.id, aws_subnet.pri_c.id]

  tags = {
    Name = "tf-db subnet group"
  }
}

resource "aws_db_instance" "tf-db" {
  identifier             = "tf-db"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.tf-db.name
  vpc_security_group_ids = [aws_security_group.db.id]
}
