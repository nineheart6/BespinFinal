# (부록) 스토리지 이름 충돌 방지용 랜덤 접미사
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Azure Storage Account (목적지)
resource "azurerm_storage_account" "dest_storage" {
  name                     = "stmigration${random_string.suffix.result}" # 전역 고유 이름 필요
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Blob Container (데이터가 담길 폴더)
resource "azurerm_storage_container" "dest_container" {
  name                  = "from-s3-data"
  storage_account_name  = azurerm_storage_account.dest_storage.name
  container_access_type = "private"
}
