terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

#현재 azure에 로그인한 정보를 가져온다.
provider "azurerm" {
    features {}
}