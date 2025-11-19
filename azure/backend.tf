terraform {
  backend "azurerm" {
    # This will be configured during initialization
    # Example configuration (uncomment and update with your values):
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "terraformstate123"
    # container_name       = "tfstate"
    # key                  = "prod.terraform.tfstate"
  }
}