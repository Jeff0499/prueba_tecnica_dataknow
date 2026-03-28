terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # Si quieres backend remoto, descomenta y configura. Por ahora lo dejamos comentado.
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstatejeferson"
  #   container_name       = "terraform-state"
  #   key                  = "prueba-tecnica.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {}
}