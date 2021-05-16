# Static group

resource "panos_zone" "example" {
    name = "outside"
    mode = "layer3"
    interfaces = [
        panos_ethernet_interface.e1.name,
    ]
    enable_user_id = true
    exclude_acls = ["192.168.0.0/16"]
}

resource "panos_zone" "example2" {
    name = "inside"
    mode = "layer3"
    interfaces = [
        panos_ethernet_interface.e5.name,
    ]
    enable_user_id = true
    exclude_acls = ["192.168.0.0/16"]
}

resource "panos_ethernet_interface" "e1" {
    name = "ethernet1/1"
    mode = "layer3"
}

resource "panos_ethernet_interface" "e5" {
    name = "ethernet1/2"
    mode = "layer3"
}

resource "panos_address_group" "example1" {
    name = "static ntp grp"
    description = "My NTP servers"
    static_addresses = [
        panos_address_object.ao1.name,
        panos_address_object.ao2.name,
    ]
}

resource "panos_address_object" "ao1" {
    name = "ntp1"
    value = "10.0.0.1"
}

resource "panos_address_object" "ao2" {
    name = "ntp2"
    value = "10.0.0.2"
}

resource "panos_security_rule_group" "policy" {
  rule {
    name                  = "IP_ALL_ACCESS"
    source_zones          = ["any"]
    source_addresses      = ["10.0.0.0/8"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
  }
  rule {
    name                  = "Outbound"
    source_zones          = ["inside"]
    source_addresses      = ["192.168.0.0/16"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    #profile               = ["${panos_panorama_monitor_profile.monitor-profile}"]
    destination_zones     = ["outside"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    #categories            = ["any"]
    action                = "allow"
  }
  rule {
    name                  = "Default Deny"
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "deny"
  }
}