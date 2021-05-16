###########################
# Let's deploy that PAN VM
# Replace any occurance of !!!CHANGE ME!!! with the appropriate values
###########################

# Storage Acct for FW disk
resource "azurerm_storage_account" "PAN_FW_STG_AC" {
  name                = var.StorageAccountName
  resource_group_name = var.ResourceGroup
  location            = var.location
  account_replication_type = "LRS"
  account_tier        = "Standard" 
}

resource "azurerm_availability_set" "fw012" {
  name                         = var.availability_set
  resource_group_name = var.ResourceGroup
  location            = var.location
  platform_update_domain_count = 5
  platform_fault_domain_count  = 2
  managed                      = true
}

# NSG For PAN Mgmt Interface
resource "azurerm_network_security_group" "pan_mgmt" {
  name                = join("", tolist([var.mgmtsubnetname, "-nsg"]))
  resource_group_name = var.ResourceGroup
  location            = var.location

# Permit inbound access to the mgmt VNIC from permitted IPs
  security_rule {
    name                       = "Allow-Intra"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    # Add the source IP address that will be used to access the FW mgmt interface
    source_address_prefixes      = ["0.0.0.0/0"]                         
    destination_address_prefix = "*"
  }
}

# Associated the NSG with PAN's mgmt subnet
resource "azurerm_subnet_network_security_group_association" "pan_mgmt" {
  subnet_id      = azurerm_subnet.fwmgmt.id
  network_security_group_id = azurerm_network_security_group.pan_mgmt.id
}


# NSG For PAN Outside Interface
resource "azurerm_network_security_group" "pan_outside" {
  name                = join("", tolist([var.outsidesubnetname, "-nsg"]))
  resource_group_name = var.ResourceGroup
  location            = var.location

# Permit inbound access to the outside VNIC from permitted IPs
  security_rule {
    name                       = "Allow-Intra"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    # Add the source IP address that will be used to access the FW outside interface
    source_address_prefixes      = ["0.0.0.0/0"]                         
    destination_address_prefix = "*"
  }
}

# Associated the NSG with PAN's outside subnet
resource "azurerm_subnet_network_security_group_association" "pan_outside" {
  subnet_id      = azurerm_subnet.fwuntrust.id
  network_security_group_id = azurerm_network_security_group.pan_outside.id
}


# NSG For PAN Inside Interface
resource "azurerm_network_security_group" "pan_inside" {
  name                = join("", tolist([var.insidesubnetname, "-nsg"]))
  resource_group_name = var.ResourceGroup
  location            = var.location

# Permit inbound access to the inside VNIC from permitted IPs
  security_rule {
    name                       = "Allow-Intra"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    # Add the source IP address that will be used to access the FW inside interface
    source_address_prefixes      = ["0.0.0.0/0"]                         
    destination_address_prefix = "*"
  }
}

# Associated the NSG with PAN's inside subnet
resource "azurerm_subnet_network_security_group_association" "pan_inside" {
  subnet_id      = azurerm_subnet.fwtrust.id
  network_security_group_id = azurerm_network_security_group.pan_inside.id
}

# Public IP for PAN mgmt Intf
resource "azurerm_public_ip" "pan_mgmt1" {
  name                = join("", tolist([var.FirewallVmName, "01-mgmtip"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
  allocation_method   = "Static"
  # Handy to give it a Domain name
  domain_name_label   = join("", tolist([var.FirewallVmName, "01domain"]))
  sku                 = "Standard"
}

# Public IP for PAN untrust interface
resource "azurerm_public_ip" "pan_untrust1" {
  name                = join("", tolist([var.FirewallVmName, "01-outpip"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
  allocation_method   = "Static"
  sku                 = "Standard"
}

# PAN mgmt VNIC
resource "azurerm_network_interface" "FW1_VNIC0" {
  name                = join("", tolist([var.FirewallVmName, "01-mgmt"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
 
  enable_accelerated_networking = true
  
  ip_configuration {
    name                          = "ipconfig0"
    subnet_id                     = azurerm_subnet.fwmgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.firewall1mgmt
    # Mgmt VNIC has static public IP address
    public_ip_address_id          = azurerm_public_ip.pan_mgmt1.id
  }

  tags = {
    panInterface = "mgmt0"
  }
}

# PAN untrust VNIC
resource "azurerm_network_interface" "FW1_VNIC1" {
  name                = join("", tolist([var.FirewallVmName, "01-outside"]))
  location            = var.location
  resource_group_name = var.ResourceGroup

# Accelerated networking supported by PAN OS image
  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.fwuntrust.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.firewall1out
    # Untrusted interface has static public IP address
    public_ip_address_id          = azurerm_public_ip.pan_untrust1.id
  }

  tags = {
    panInterface = "ethernet1/1"
  }
}

# PAN trust VNIC
resource "azurerm_network_interface" "FW1_VNIC2" {
  name                = join("", tolist([var.FirewallVmName, "01-inside"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
  
  # Accelerated networking supported by PAN OS image
  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = azurerm_subnet.fwtrust.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.firewall1ins
  }

  tags = {
    panInterface = "ethernet1/2"
  }
}

# Create the firewall VM
resource "azurerm_virtual_machine" "PAN_FW_FW1" {
  name                  = join("", tolist([var.FirewallVmName, "01"]))
  location              = var.location
  resource_group_name   = var.ResourceGroup
  # The ARM templates for PAN OS VM use specific machine size - using same here
  vm_size               = var.vmsize
  availability_set_id = azurerm_availability_set.fw012.id

  plan {
    # Using a pay as you go license set sku to "bundle2"
    # To use a purchased license change sku to "byol"
    name      = var.vmplan
    publisher = var.vmpublisher
    product   = var.vmproduct
  }

  storage_image_reference {
    publisher = var.vmpublisher
    offer     = var.vmproduct
    # Using a pay as you go license set sku to "bundle2"
    # To use a purchased license change sku to "byol"
    sku       = var.vmplan
    version   = var.vmversion
  }

  storage_os_disk {
    name          = join("", tolist([var.FirewallVmName, "01-osdisk"]))
    caching       = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = join("", tolist([var.FirewallVmName, "01"]))
    admin_username = var.vmusername
    admin_password = var.vmpassword
  }
  # The ordering of interaces assignewd here controls the PAN OS device mapping
  # 1st = mgmt0, 2nd = Ethernet1/1, 3rd = Ethernet 1/2 
  primary_network_interface_id = azurerm_network_interface.FW1_VNIC0.id
  network_interface_ids = [azurerm_network_interface.FW1_VNIC0.id,
                           azurerm_network_interface.FW1_VNIC1.id,
                           azurerm_network_interface.FW1_VNIC2.id ]

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Public IP for PAN mgmt Intf
resource "azurerm_public_ip" "pan_mgmt2" {
  name                = join("", tolist([var.FirewallVmName, "02-mgmtip"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
  allocation_method   = "Static"
  # Handy to give it a Domain name
  domain_name_label   = join("", tolist([var.FirewallVmName, "02domain"]))
  sku                 = "Standard"
}

# Public IP for PAN untrust interface
resource "azurerm_public_ip" "pan_untrust2" {
  name                = join("", tolist([var.FirewallVmName, "02-outpip"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
  allocation_method   = "Static"
  sku                 = "Standard"
}

# PAN mgmt VNIC
resource "azurerm_network_interface" "FW2_VNIC0" {
  name                = join("", tolist([var.FirewallVmName, "02-mgmt"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
 
  enable_accelerated_networking = true
  
  ip_configuration {
    name                          = "ipconfig0"
    subnet_id                     = azurerm_subnet.fwmgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.firewall2mgmt
    # Mgmt VNIC has static public IP address
    public_ip_address_id          = azurerm_public_ip.pan_mgmt2.id
  }

  tags = {
    panInterface = "mgmt0"
  }
}

# PAN untrust VNIC
resource "azurerm_network_interface" "FW2_VNIC1" {
  name                = join("", tolist([var.FirewallVmName, "02-outside"]))
  location            = var.location
  resource_group_name = var.ResourceGroup

# Accelerated networking supported by PAN OS image
  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.fwuntrust.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.firewall2out
    # Untrusted interface has static public IP address
    public_ip_address_id          = azurerm_public_ip.pan_untrust2.id
  }

  tags = {
    panInterface = "ethernet1/1"
  }
}

# PAN trust VNIC
resource "azurerm_network_interface" "FW2_VNIC2" {
  name                = join("", tolist([var.FirewallVmName, "02-inside"]))
  location            = var.location
  resource_group_name = var.ResourceGroup
  
  # Accelerated networking supported by PAN OS image
  enable_accelerated_networking = true
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = azurerm_subnet.fwtrust.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.firewall2ins
  }

  tags = {
    panInterface = "ethernet1/2"
  }
}

# Create the firewall VM
resource "azurerm_virtual_machine" "PAN_FW_FW2" {
  name                  = join("", tolist([var.FirewallVmName, "02"]))
  location              = var.location
  resource_group_name   = var.ResourceGroup
  # The ARM templates for PAN OS VM use specific machine size - using same here
  vm_size               = var.vmsize
  availability_set_id = azurerm_availability_set.fw012.id

  plan {
    # Using a pay as you go license set sku to "bundle2"
    # To use a purchased license change sku to "byol"
    name      = var.vmplan
    publisher = var.vmpublisher
    product   = var.vmproduct
  }

  storage_image_reference {
    publisher = var.vmpublisher
    offer     = var.vmproduct
    # Using a pay as you go license set sku to "bundle2"
    # To use a purchased license change sku to "byol"
    sku       = var.vmplan
    version   = var.vmversion
  }

  storage_os_disk {
    name          = join("", tolist([var.FirewallVmName, "02-osdisk"]))
    caching       = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = join("", tolist([var.FirewallVmName, "02"]))
    admin_username = var.vmusername
    admin_password = var.vmpassword
  }
  # The ordering of interaces assignewd here controls the PAN OS device mapping
  # 1st = mgmt0, 2nd = Ethernet1/1, 3rd = Ethernet 1/2 
  primary_network_interface_id = azurerm_network_interface.FW2_VNIC0.id
  network_interface_ids = [azurerm_network_interface.FW2_VNIC0.id,
                           azurerm_network_interface.FW2_VNIC1.id,
                           azurerm_network_interface.FW2_VNIC2.id ]

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
