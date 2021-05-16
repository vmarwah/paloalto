terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "1.8.3"
    }
  }
}

provider "panos" {  
  hostname = "<hostname or IP address>"
  username = "panadmin"
  password = "p@ssw0rd@123"
}


