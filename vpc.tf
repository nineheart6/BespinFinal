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
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
  #subnet안에서 ec2생성시 public ip 자동 할딩
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-subnet-public1-ap-northeast-2a"
  }
}

resource "aws_subnet" "pub_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
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

#### private 서브넷 구성 ####

resource "aws_subnet" "pri_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tf-subnet-private1-ap-northeast-2a"
  }
}

resource "aws_subnet" "pri_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "tf-subnet-private2-ap-northeast-2c"
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
resource "aws_route_table_association" "pri_a" {
  subnet_id      = aws_subnet.pri_a.id
  route_table_id = aws_route_table.pri_a.id
}

resource "aws_route_table_association" "pri_c" {
  subnet_id      = aws_subnet.pri_c.id
  route_table_id = aws_route_table.pri_c.id
}