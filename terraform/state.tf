terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate7859"
    container_name       = "tfstate"
    key                  = "clincha_terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg-tfstate" {
  name     = "tfstate"
  location = "eu-west-2"
}
