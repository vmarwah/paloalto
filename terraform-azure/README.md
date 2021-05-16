# Deploy 2 Palo Alto firewalls in availability set configuration on Azure using Terraform

# PreRequisites:
1) VNET already created on Azure having below details -
- VNET Name - firewallvnet
- VNET Resource group - firewallrg
- VNET IP - 172.20.0.0/16
2) Resource group where firewalls are going to be deployed is already created i.e. 'firewallrg'
 
 # Templates:
 
 # 1) main.tf 
 This template defines -
 - Provider which is azurerm having minimum version =>2.0
 - Mangement subnet
 - Outside subnet
 - Inside subnet
  
  # 2) pan.tf
  This template defines -
  - Storage account
  - Availability set
  - NSG on management, outside and inside siubnet
  - Public IP for management and outside interface
  - Private IP for management, outside and inside interface
  - Firewall VM plan, publisher, product
  
  # 3) variables.tf
  This template defines different variables used in above templates
  
  # 4) terraform.tfvars
  This template defines different variables values which can be modified as per the requirement.
  
 
