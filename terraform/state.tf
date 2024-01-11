terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "clincha"
    container_name       = "tfstate"
    key                  = "clincha.tfstate"
  }
}
