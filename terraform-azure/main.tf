provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

###########################
# Define subnets 
###########################

# PAN mgmt interface
resource "azurerm_subnet" "fwmgmt" {
  name                 = var.mgmtsubnetname
  resource_group_name  = var.vnetResourceGroup
  virtual_network_name = var.virtualnetwork
  address_prefixes     = var.mgmtsubnet
}

# PAN FW outside
resource "azurerm_subnet" "fwuntrust" {
  name                 = var.outsidesubnetname
  resource_group_name  = var.vnetResourceGroup
  virtual_network_name = var.virtualnetwork
  address_prefixes     = var.outsidesubnet
}

# PAN FW inside
resource "azurerm_subnet" "fwtrust" {
  name                 = var.insidesubnetname
  resource_group_name  = var.vnetResourceGroup
  virtual_network_name = var.virtualnetwork
  address_prefixes     = var.insidesubnet
}
