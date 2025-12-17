# BespinFinal
VPN, DMS 테스트를 위한 테라폼
## Aws 구현사항
기본 인프라 + bastion 서버 코드
VPN, route53 resolver

### 추가
AWS DMS 테스트(
DMS는 콘솔에서 진행)

## Azure
기본 vm,db,private resolver

### Azure 사전 설정
```
#AzureCLI설치
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#login하기
az login
#윈도우 로그인이 어려울 때
#az login --use-device-code
#azure 구독 아이디 확인
az account list --output table
```

## 추가
### 키 파일 위치 
ssh_public_key_path = "../keys/mykey.pub"

```
mkdir keys
cd keys
ssh-keygen -m PEM -f mykey -N ""
```
AWS, AZURE 폴더 사용.

기본적인 bastion 서버1개 rds 1개와 퍼블릭/프라이빗 서브넷을 만드는 코드가 베이스.

## 용어

### 1. BGP (Border Gateway Protocol)

**인터넷의 내비게이션 시스템**

BGP는 인터넷상에서 데이터가 이동하는 **경로를 결정하는 프로토콜**입니다. 인터넷은 수많은 작은 네트워크(AS: Autonomous System, 자율 시스템)들의 집합체인데, BGP는 이 네트워크들 사이에서 가장 효율적인 경로가 어디인지 서로 정보를 교환하고 길을 찾아줍니다.

아래의 코드는 BGP가 아닌 정적 ip로 직접 알려준 코드

### 2. DNS Resolver (DNS 리졸버)

**인터넷 주소 검색 대행자**

우리가 브라우저에 `google.com`을 입력하면 컴퓨터는 이 문자를 이해하지 못합니다. 컴퓨터가 이해하는 IP 주소(예: `142.250.xxx.xxx`)로 변환해야 하는데, 이 과정을 **대신 수행해 주는 서버**가 DNS Resolver입니다.

- **작동 방식:**
    1. 사용자가 도메인 입력을 하면 컴퓨터는 가장 먼저 **DNS Resolver**에게 "이 주소의 IP가 뭐니?"라고 묻습니다. (주로 ISP나 통신사가 제공하거나, 8.8.8.8 같은 공용 DNS를 사용)
    2. DNS Resolver는 정답을 찾을 때까지 루트 서버(Root Server), 최상위 도메인 서버(TLD Server) 등을 차례로 방문하며 **재귀적(Recursive)으로 질문**을 던집니다.
    3. 최종 IP 주소를 알아내면 사용자에게 전달해 줍니다.

### 3. VPN Gateway와 Customer Gateway

이 두 용어는 주로 AWS와 같은 **클라우드 환경과 기업의 온프레미스(사내 데이터센터)를 VPN으로 연결할 때** 짝을 이루어 등장하는 개념입니다. (Site-to-Site VPN 연결)

### **VPN Gateway (VGW)**

- **위치:** **클라우드(Provider) 측** (예: AWS VPC 내부)
- **역할:** 클라우드 네트워크의 대문 역할을 합니다. 클라우드 내부의 자원들이 외부와 VPN 통신을 할 때 거쳐가는 관문입니다.
- **특징:** 클라우드 제공자가 관리하며, 사용자는 단순히 생성하여 자신의 클라우드 네트워크(VPC)에 부착(Attach)하기만 하면 됩니다.

### **Customer Gateway (CGW)**

- **위치:** **고객(Customer) 측** (예: 회사의 물리적 데이터센터)
- **역할:** 고객 측 네트워크의 대문 역할을 합니다.

# 코드 실행 환경(aws에서 bastion에 권한 주고 실행)

1. 사전 설정 코드
    
    ```jsx
    # azure login
    az login
    az account list
    # 키 위치: /home/ubuntu/task/BespinFinal/keys
    mkdir keys
    cd keys
    ssh-keygen -m PEM -f mykey -N ""
    ```
    
2. azure, aws의 terraform.tfvars
    
    ```jsx
    #####################
    #### AZURE ####
    #######################
    # 변수 값 설정
    resource_group_name = "rg-migration-demo"
    location            = "koreacentral"
    vm_name             = "petclinic"
    admin_username      = "ubuntu"
    
    # 키 파일 경로 설정
    # 상대 경로는 ../keys/mykey.pub 입니다.
    ssh_public_key_path = "../keys/mykey.pub"
    
    #az account list의 자신의 구독 id
    subscription_id = ""
    
    db_admin_username = "petclinic"
    # 대,소문자,숫자,특수문자 중 3개 이상 섞기
    db_admin_password = "Password@@"
    
    ################# 중요 #########################
    # --- AWS terraform apply 이후 콘솔 보고 채워넣기 ---
    # 설정한AWS VPC 대역
    aws_vpc_cidr      = "10.0.0.0/16"                                          
    # AWS Site-to-Site VPN 연결의 '터널 1 외부 IP 주소'
    aws_vpn_public_ip = "13.124.173.51"
    # AWS 터널 옵션의 '사전 공유 키(PSK)'
    vpn_shared_key    = "P0wqlnJpkd6MVk7VOJSylbiNfaB6HUTb" 
    ```
    
    ```jsx
    #######################
    #### AWS ####
    #######################
    
    # 변수 값 설정
    instance_type               = "t3.micro"
    server_port                 = 80
    bastion_security_group_name = "bastion-SG"
    db_security_group_name      = "DB-SG"
    db_username                 = "admin"
    db_name                     = "terraform"
    db_password                 = "password"
    my_ip                       = "0.0.0.0/0" #자신의 ip
    key_path                    = "../keys/mykey.pub"
    
    # Azure VPN 정보 (실제 Azure apply 이후 나온 값들로 변경 필요)
    azure_public_ip = "20.196.95.111"  
    #azure_bgp_asn   = 65515           # Azure 기본 ASN
    azure_bgp_asn   = 65000           # 정적 라우팅 기본 ASN
    azure_cidr      = "192.168.0.0/16" 
    azure_dns_ip = "192.168.200.4"
    
    ```
    

# 실행순서

1. 사전 설정 이후 Azure/network.tf에 141번째 라인부터 끝 줄까지 주석처리
2. Azure폴더 내부에서 terraform apply
3. Azure output에서 나온 값들을 Aws 폴더의 tfvars에 넣고 apply.
4. Azure/network.tf에서 주석 해제 후 tfvars에 aws에 나온 값을 넣고 다시 apply.
5. 그럼 VPN이 연결 된 상태.

# 코드에 대해서 설명

기본적인 코드에서 벗어난 부분

- Azure/network.tf
    
    ```jsx
    
    # ---------------------------------------------------------
    # [추가] VPN Gateway 관련 리소스
    # ---------------------------------------------------------
    
    # 6. Gateway 전용 서브넷 (이름은 반드시 GatewaySubnet 이어야 함)
    resource "azurerm_subnet" "gateway_subnet" {
      name                 = "GatewaySubnet"
      resource_group_name  = azurerm_resource_group.rg.name
      virtual_network_name = azurerm_virtual_network.vnet.name
      address_prefixes     = ["192.168.255.0/24"]
    }
    
    # 7. VPN Gateway용 공인 IP
    resource "azurerm_public_ip" "vpn_pip" {
      name                = "vpn-gateway-pip"
      resource_group_name = azurerm_resource_group.rg.name
      location            = azurerm_resource_group.rg.location
      sku                 = "Standard"
      allocation_method   = "Static"
    }
    
    # 8. Virtual Network Gateway (VPN Gateway 본체)
    resource "azurerm_virtual_network_gateway" "vpn_gateway" {
      name                = "migration-vpn-gateway"
      location            = azurerm_resource_group.rg.location
      resource_group_name = azurerm_resource_group.rg.name
    
      #암호화 설정
      type     = "Vpn"
      vpn_type = "RouteBased"
    
      active_active = false
      enable_bgp    = false
      sku           = "VpnGw1" # 실습용으로 적절 (Basic은 제약이 많음)
      generation    = "Generation1"
    
      ip_configuration {
        name                          = "vnetGatewayConfig"
        public_ip_address_id          = azurerm_public_ip.vpn_pip.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = azurerm_subnet.gateway_subnet.id
      }
    }
    # ---------------------------------------------------------
    # vpn connection
    # ---------------------------------------------------------
    # AWS 완료 후 주석 풀고 값 넣고 실행
    # 1. Local Network Gateway (AWS의 정보를 Azure에 등록)
    resource "azurerm_local_network_gateway" "aws_lng" {
      name                = "aws-local-gateway"
      resource_group_name = azurerm_resource_group.rg.name
      location            = azurerm_resource_group.rg.location
    
      # AWS VPN 터널의 외부 IP (3.x.x.x 등)
      gateway_address = var.aws_vpn_public_ip
    
      # AWS VPC 내부 CIDR (10.0.0.0/16 등) - 라우팅을 위해 필수
      address_space = [var.aws_vpc_cidr]
    }
    
    # 2. Connection (Azure Gateway와 AWS Gateway를 연결)
    resource "azurerm_virtual_network_gateway_connection" "azure_to_aws" {
      name                = "azure-to-aws-connection"
      location            = azurerm_resource_group.rg.location
      resource_group_name = azurerm_resource_group.rg.name
    
      type                       = "IPsec"
      virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
      local_network_gateway_id   = azurerm_local_network_gateway.aws_lng.id
    
      # AWS에서 설정한 Pre-Shared Key와 동일해야 함
      shared_key = var.vpn_shared_key
    }
    ```
    
- Aws/vpc.tf
    
    ```jsx
    #### vpn gateway ####
    
    # 1. VPN Gateway (VGW) - AWS측 관문
    resource "aws_vpn_gateway" "main" {
      #라우팅 오류 해결을 위한 분리 작업
      #vpc_id = aws_vpc.main.id
      tags = {
        Name = "tf-vpn-aws-gateway"
      }
    }
    
    # 1-2. [신규] VGW와 VPC를 명시적으로 연결 (Attachment)
    resource "aws_vpn_gateway_attachment" "vpn_attachment" {
      vpc_id         = aws_vpc.main.id
      vpn_gateway_id = aws_vpn_gateway.main.id
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
      depends_on = [aws_vpn_gateway_attachment.vpn_attachment]
    }
    
    resource "aws_route" "vpn_access_pri_a" {
      route_table_id         = aws_route_table.pri.id
      destination_cidr_block = var.azure_cidr
      gateway_id             = aws_vpn_gateway.main.id
      depends_on = [aws_vpn_gateway_attachment.vpn_attachment]
    }
    ```
    

DNS resolver 관련 설정은 dms를 위한 설정. 우선 제외

코드 실행 순서에 따라 설명하자면 

우선 Azure에서 apply 시

1. Gateway 전용 서브넷을 만든다.
2. VPN Gateway용 공인 IP(static ip)를 지정한다.
3. Virtual Network Gateway를 생성한다. 
    1. 그럼 azure에서 aws의 vpn에 입력할 Azure VPN 정보, Azure의 Vnet(VPC)정보가 나온다. 
    azure_public_ip = "20.196.95.111"  
    azure_bgp_asn   = 65000           # 정적 라우팅 시의 기본 ASN
    azure_cidr      = "192.168.0.0/16" 
    ~~azure_dns_ip = "192.168.200.4"~~ # DMS를 위해 필요한 설정

그리고 AWS에서 apply 시

1. AWS가 주어진 AWS의 VPC설정을 보고 그에 맞는 vpn gateway를 만든다.
2. Azure의 Vnet으로  Customer Gateway를 만든다.
3. VPN Connection으로 vpn gateway, Customer Gateway에 대해서 연결하는 통로를 구축한다.
4. 그 통로의 정보가 output 되는 것(고가용성을 위해 2개의 통로지만 1개만 테스트로 사용)

그리고 Azure에서 주석 풀고 apply

1. AWS의 통로에 대한 정보와 AWS의 VPC 관련 정보들을 Azure에 입력하여 서로 네트워크를 인지하게 한다. 

추가

1. AWS의 경우에는 Azure의 Cidr값 범위 (위의 코드에서는 192.168.0.0/16)을 라우트 테이블에 등록해 두어야 한다.
## Route53 test
1. alb에 대한 https 접속 테스트(콘솔 사용)
2. route53 failover test