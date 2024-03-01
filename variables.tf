variable "resource_group_name" {
  type        = string
  description = "Resource Group name for VNET"
}

variable "location" {
  type        = string
  description = "Location for VNET"
}

variable "vnet" {
  description = "Virtual Networks object"
  type = object({
    vnet_name      = string
    address_prefix = list(string)
    dns_servers    = list(string)
  })
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "subnets" {
  description = "Subnets object"
  type = map(object({
    subnet_name                   = string
    address_prefixes              = list(string)
    existing_nsg                  = optional(bool, false)
    existing_nsg_id               = optional(string, null)
    disable_nsg                   = optional(bool, false)
    disable_rt                    = optional(bool, false)
    existing_rt                   = optional(bool, false)
    existing_rt_id                = optional(string, null)
    disable_bgp_route_propagation = optional(bool)
    delegation = optional(map(object({
      name = optional(string)
      service_delegation = optional(object({
        name    = optional(string)
        actions = optional(list(string))
      }))
    })), {})
    nsg = map(object({
      security_rules = object({
        nsg_inbound_rules  = optional(list(list(string)), [])
        nsg_outbound_rules = optional(list(list(string)), [])
      })
    }))
    service_endpoints = list(string)
    route_table = map(object({
      routes = map(object({
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      }))

    }))
  }))
}