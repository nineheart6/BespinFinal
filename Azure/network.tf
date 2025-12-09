
# 1. 리소스 그룹: 모든 리소스를 묶어서 관리하는 논리적 컨테이너
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. 가상 네트워크 (VNet): 사설 네트워크 공간 정의
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"] # 10.0.x.x 대역 전체 사용
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. 서브넷: VNet을 더 작게 쪼갠 단위 (실제 VM이 배치되는 곳)
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"] # 10.0.1.x 대역 사용
  
}

# [추가] MySQL Flexible Server 전용 서브넷 (Delegation 필수)
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# 4. 공인 IP (Public IP): 외부에서 인터넷을 통해 접속하기 위한 IP
resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  # Static: IP가 변하지 않음 (서버용으로 적합)
  # Dynamic: VM 재부팅 시 IP가 변경될 수 있음
  # Standard SKU는 반드시 Static
  allocation_method   = "Static"
  #기본값
  #sku                 = "Standard" # Availability Zone 등을 지원하는 표준 SKU
}
