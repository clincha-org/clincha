terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstateclincha"
    container_name       = "tfstate"
    key                  = "clincha.tfstate"
  }
}
