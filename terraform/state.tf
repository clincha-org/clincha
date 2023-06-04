terraform {
  backend "azurerm" {
    tenant_id            = "5bdbf6b9-7155-49e5-a3ce-f265fd5ec77e"
    subscription_id      = "c6ff6270-64cf-40d6-ae87-e11cca58de61"
    resource_group_name  = "tfstate"
    storage_account_name = "tfstateclincha"
    container_name       = "tfstateclincha"
    key                  = "clincha_terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg-tfstate" {
  name     = "tfstate"
  location = "eu-west-2"
}
