# 1. 기존에 생성된 Route 53 Hosted Zone 정보 조회
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# 2. Health Checks (이전과 동일)
resource "aws_route53_health_check" "web_health" {
  count             = 2
  ip_address        = aws_instance.web[count.index].public_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "HealthCheck-${count.index + 1}"
  }
}

# 3. DNS Records (Failover)
# Primary (조회한 zone_id 사용)
resource "aws_route53_record" "www_primary" {
  zone_id = data.aws_route53_zone.selected.zone_id # 자동 조회된 ID 사용
  name    = "failover.${var.domain_name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.web[0].public_ip]

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary-server"
  health_check_id = aws_route53_health_check.web_health[0].id
}

# Secondary
resource "aws_route53_record" "www_secondary" {
  zone_id = data.aws_route53_zone.selected.zone_id # 자동 조회된 ID 사용
  name    = "failover.${var.domain_name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.web[1].public_ip]

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "secondary-server"
  health_check_id = aws_route53_health_check.web_health[1].id
}