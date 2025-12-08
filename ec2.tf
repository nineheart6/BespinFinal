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
resource "aws_security_group" "web" {
  name        = var.web_security_group_name
  description = "Allow HTTP inbound traffic from alb"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = var.web_security_group_name
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from alb"
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH from VPC"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip
}

resource "aws_vpc_security_group_egress_rule" "allow_all_web" {
  security_group_id = aws_security_group.web.id
  description       = "outbound_all"
  #0 사용 금지
  from_port   = -1
  to_port     = -1
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_launch_template" "web" {
  name = "lt-web"
  #아래와 동일
  #image_id = "${var.image_id == "" ? data.aws_ami.al2023.id : var.image_id}"
  image_id               = coalesce(var.image_id, data.aws_ami.al2023.id)
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring { enabled = true }
  key_name = aws_key_pair.mykey.key_name
  #default_version = 지정하지 않으면 latest로 추가.
  #update_default_version은 default를 계속 변경
  user_data = base64encode(templatefile("${path.module}/userdata.tftpl", {
    server_port = var.server_port
    db_username = var.db_username
    db_password = var.db_password
    db_name     = var.db_name
    db_endpoint = aws_db_instance.tf-db.address
    })
  )
  #db,NAT 생성 이후에 ec2 생성
  depends_on = [aws_nat_gateway.pri_a, aws_db_instance.tf-db]
}

resource "aws_autoscaling_group" "web" {
  name = "asg-web"

  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.pri_a.id, aws_subnet.pri_c.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  #로드벨런서를 위한 타겟 그룹
  target_group_arns = [aws_lb_target_group.asg.arn]
  #ALB에서 헬스체크
  health_check_type = "ELB"
  #새로운 인스턴스가 InService 상태가 된 후, ASG가 헬스 체크 실패를 무시하고 기다려주는 시간
  #만일 userdata가 장기간 소요시 다시 늘릴 것.
  health_check_grace_period = 60 #Default: 300
  #스케일링 간 대기시간
  default_cooldown = 60

  tag {
    key   = "Name"
    value = "tf-asg-web"
    #이 ASG를 통해 시작한 EC2로 태그 전파 
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      #최소 절반은 정상으로 유지
      min_healthy_percentage = 50
      #속도 증가를 위한 시작 대기 시간 감소
      instance_warmup = 60
    }
  }
}


#### Compute - ALB ####
#alb SG
resource "aws_security_group" "alb" {
  name        = var.alb_security_group_name
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from VPC"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_to_ec2" {
  security_group_id            = aws_security_group.alb.id
  description                  = "http from alb"
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
}

resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.pub_a.id,
    aws_subnet.pub_c.id
  ]
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = var.alb_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found\n"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_target_group" "asg" {
  name_prefix = "tf"
  port        = var.server_port #80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  #종료 전 대기시간
  deregistration_delay = 60 # 기본값 300

  #옵션
  health_check {
    path     = "/"
    protocol = "HTTP"
    #합격 기준
    matcher = "200"
    #검사 주기
    interval = 15
    #응답 대기 시간
    timeout = 3
    #정상 판정 임계값
    healthy_threshold = 2
    #고장 판정 임계값
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}