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
resource "aws_route" "vpn_access_pub" {
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
}