#vpc 설계
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  #dns로 접속하기 위한 옵션
  #enable_dns_support = true (default)
  enable_dns_hostnames = true

  tags = {
    "Name" = "tf-vpc"
  }
}

#### public 서브넷 구성 ####

resource "aws_subnet" "pub_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "ap-northeast-2a"
  #subnet안에서 ec2생성시 public ip 자동 할딩
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-subnet-public1-ap-northeast-2a"
  }
}

resource "aws_subnet" "pub_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/25"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-subnet-public2-ap-northeast-2c"
  }
}

#igw 생성
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "tf-igw"
  }
}

#route table 생성(+igw 연결)
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "tf-rtb-public-ap-northeast"
  }
}

#route에 subnet 등록
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_c" {
  subnet_id      = aws_subnet.pub_c.id
  route_table_id = aws_route_table.pub.id
}

#### db private 서브넷 구성 ####

resource "aws_subnet" "db_pri_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/25"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tf-db-subnet-private1-ap-northeast-2a"
  }
}

resource "aws_subnet" "db_pri_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/25"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "tf-db-subnet-private2-ap-northeast-2c"
  }
}

#nat-gateway용 eip
resource "aws_eip" "pub_a" {
  domain = "vpc"

  tags = {
    "Name" = "tf-eip-ap-northeast-2a"
  }
}

resource "aws_eip" "pub_c" {
  domain = "vpc"

  tags = {
    "Name" = "tf-eip-ap-northeast-2c"
  }
}

#nat 생성
resource "aws_nat_gateway" "pri_a" {
  subnet_id     = aws_subnet.pub_a.id
  allocation_id = aws_eip.pub_a.id

  tags = {
    "Name" = "tf-nat-public1-ap-northeast-2a"
  }

  #recommend
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "pri_c" {
  subnet_id     = aws_subnet.pub_c.id
  allocation_id = aws_eip.pub_c.id

  tags = {
    "Name" = "tf-nat-public1-ap-northeast-2a"
  }

  #recommend
  depends_on = [aws_internet_gateway.gw]
}

#route table 생성(+nat 할당)
resource "aws_route_table" "pri_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pri_a.id
  }


  tags = {
    Name = "tf-rtb-private1-ap-northeast-2a"
  }
}

resource "aws_route_table" "pri_c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pri_c.id
  }

  tags = {
    Name = "tf-rtb-private2-ap-northeast-2c"
  }
}

#route에 subnet 등록
resource "aws_route_table_association" "db_pri_a" {
  subnet_id      = aws_subnet.db_pri_a.id
  route_table_id = aws_route_table.pri_a.id
}

resource "aws_route_table_association" "db_pri_c" {
  subnet_id      = aws_subnet.db_pri_c.id
  route_table_id = aws_route_table.pri_c.id
}

### eks private 서브넷 구성 ###

resource "aws_subnet" "eks_pri_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tf-eks-subnet-private1-ap-northeast-2a"
  }
}

resource "aws_subnet" "eks_pri_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.128/25"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "tf-eks-subnet-private2-ap-northeast-2c"
  }
}

#route에 subnet 등록
resource "aws_route_table_association" "eks_pri_a" {
  subnet_id      = aws_subnet.eks_pri_a.id
  route_table_id = aws_route_table.pri_a.id
}

resource "aws_route_table_association" "eks_pri_c" {
  subnet_id      = aws_subnet.eks_pri_c.id
  route_table_id = aws_route_table.pri_c.id
}

#### vpn gateway ####

# 1. VPN Gateway (VGW) - AWS측 관문
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-vpn-aws-gateway"
  }
}

# 2. Customer Gateway (CGW) - 고객(온프레미스)측 관문
resource "aws_customer_gateway" "main" {
  bgp_asn    = var.azure_bgp_asn 
  ip_address = var.azure_public_ip
  type       = "ipsec.1"

  tags = {
    Name = "tf-customer-azure-gateway"
  }
}

# 3. VPN Connection - VGW와 CGW 연결
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true # BGP를 안 쓴다면 True로 설정

  tags = {
    Name = "tf-vpn-connection"
  }
}

# 4. [중요!] VPN Static Route 추가
# "이 CIDR 대역은 VPN 건너편에 있으니 VPN 터널로 보내라"고 정의
resource "aws_vpn_connection_route" "azure" {
  destination_cidr_block = var.azure_cidr
  vpn_connection_id      = aws_vpn_connection.main.id
}

# 5. VPC Route Table에 명시적 라우트 추가
# "Propagation(자동 전파)" 대신 "Route(수동 추가)" 사용
/* resource "aws_route" "vpn_access_pub" {
  route_table_id         = aws_route_table.pub.id
  destination_cidr_block = var.azure_cidr
  gateway_id             = aws_vpn_gateway.main.id
}

resource "aws_route" "vpn_access_pri_a" {
  route_table_id         = aws_route_table.pri_a.id
  destination_cidr_block = var.azure_cidr
  gateway_id             = aws_vpn_gateway.main.id
}

resource "aws_route" "vpn_access_pri_c" {
  route_table_id         = aws_route_table.pri_c.id
  destination_cidr_block = var.azure_cidr
  gateway_id             = aws_vpn_gateway.main.id
} */

# Public Route Table에 VPN 경로 전파
resource "aws_vpn_gateway_route_propagation" "pub" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.pub.id
}

# Private Route Table A에 VPN 경로 전파
resource "aws_vpn_gateway_route_propagation" "pri_a" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.pri_a.id
}

# Private Route Table C에 VPN 경로 전파
resource "aws_vpn_gateway_route_propagation" "pri_c" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.pri_c.id
}

####################################################
# aws_route53_resolver로 azure dns reslover를 사용
####################################################
# 1. Resolver용 Security Group 생성
# (AWS에서 Azure 쪽으로 DNS 쿼리(UDP/TCP 53)가 나갈 수 있게 허용해야 합니다)
resource "aws_security_group" "dns_resolver_sg" {
  name        = "dns-resolver-outbound-sg"
  description = "Allow DNS outbound traffic to Azure"
  vpc_id      = aws_vpc.main.id # 사용자의 VPC ID 참조

  # Outbound: DNS 쿼리(53)를 모든 곳(또는 Azure VPN 대역)으로 허용
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Route 53 Resolver Outbound Endpoint 생성
# (AWS VPC -> 외부로 쿼리를 던지는 출구 인터페이스)
resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "azure-dns-outbound-endpoint"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.dns_resolver_sg.id]

  # 최소 2개의 가용 영역(AZ)에 있는 서브넷 지정 권장
  ip_address {
    subnet_id = aws_subnet.db_pri_a.id # 사용자의 서브넷 ID 1
  }

  ip_address {
    subnet_id = aws_subnet.db_pri_c.id # 사용자의 서브넷 ID 2
  }
}

# 3. Resolver Rule 생성 (핵심 로직)
resource "aws_route53_resolver_rule" "azure_mysql_rule" {
  name                 = "forward-azure-mysql"
  domain_name          = "mysql.database.azure.com" # 포워딩할 도메인 (와일드카드 포함됨)
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = var.azure_dns_ip
  }
  
  # 만약 Azure DNS 서버가 여러 대라면 target_ip 블록을 추가
  # target_ip {
  #   ip = "192.169.200.5" 
  # }
}

# 4. Rule을 VPC에 연결 (Association)
# 이 설정이 있어야 실제 VPC 내의 인스턴스들이 이 규칙을 사용합니다.
resource "aws_route53_resolver_rule_association" "azure_mysql_assoc" {
  resolver_rule_id = aws_route53_resolver_rule.azure_mysql_rule.id
  vpc_id           = aws_vpc.main.id # 규칙을 적용할 VPC ID
}