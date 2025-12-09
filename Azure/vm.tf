# -------------------------------------------------------------------
# 컴퓨팅 리소스 (VM) 구성
# 실제 서버와 랜카드(NIC)를 생성합니다.
# -------------------------------------------------------------------

# 1. 네트워크 인터페이스 (NIC): 가상 랜카드
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id # 위에서 만든 서브넷에 연결
    private_ip_address_allocation = "Dynamic"                # 사설 IP는 자동 할당
    public_ip_address_id          = azurerm_public_ip.pip.id # 공인 IP 연결
  }
}

# 2. NIC와 NSG 연결: 랜카드에 방화벽 규칙 적용
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 3. 리눅스 가상 머신 생성
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1s" # VM 크기 (CPU, RAM 사양)
  admin_username      = var.admin_username

  # 위에서 만든 NIC 연결
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # SSH 키 설정 (비밀번호 방식보다 보안 우수)
  admin_ssh_key {
    username = var.admin_username
    # file() 함수: 로컬 경로에 있는 파일의 내용을 텍스트로 읽어옵니다.
    public_key = file(var.ssh_public_key_path)
  }

  # OS 디스크 설정
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # 표준 HDD/SSD (비용 절감)
  }

  # 운영체제 이미지 정보 (Ubuntu 22.04 LTS)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}