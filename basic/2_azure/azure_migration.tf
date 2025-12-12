# 1. 리소스 그룹 생성
resource "azurerm_resource_group" "migration_rg" {
  name     = "rg-s3-migration"
  location = "Korea Central"
}

# 2. Azure Storage Account (목적지)
resource "azurerm_storage_account" "dest_storage" {
  name                     = "stmigration${random_string.suffix.result}" # 전역 고유 이름 필요
  resource_group_name      = azurerm_resource_group.migration_rg.name
  location                 = azurerm_resource_group.migration_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Blob Container (데이터가 담길 폴더)
resource "azurerm_storage_container" "dest_container" {
  name                  = "from-s3-data"
  storage_account_name  = azurerm_storage_account.dest_storage.name
  container_access_type = "private"
}

# 4. Azure Data Factory (마이그레이션 도구)
resource "azurerm_data_factory" "adf" {
  name                = "adf-s3-migration-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.migration_rg.name
  location            = azurerm_resource_group.migration_rg.location
}

# 5. Linked Service: Azure Blob Storage (목적지 연결)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "ls_blob" {
  name              = "ls_azure_blob"
  data_factory_id   = azurerm_data_factory.adf.id
  connection_string = azurerm_storage_account.dest_storage.primary_connection_string
}

# 6. Linked Service: AWS S3 (출발지 연결)
resource "azurerm_data_factory_linked_service_amazon_s3" "ls_s3" {
  name            = "ls_aws_s3"
  data_factory_id = azurerm_data_factory.adf.id
  
  # AWS 접근 키 (변수로 입력받음)
  access_key_id     = var.aws_access_key
  secret_access_key = var.aws_secret_key
  
  # 특정 버킷을 지정하고 싶다면 아래 주석 해제 (옵션)
  # service_url = "https://s3.ap-northeast-2.amazonaws.com" 
}

# (부록) 스토리지 이름 충돌 방지용 랜덤 접미사
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}