## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_route_table.rt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet.snet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.nsg-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.nsg-association-existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.rt-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.rt-association-existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_resource_group.vnet_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Location for VNET | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group name for VNET | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets object | <pre>map(object({<br>    subnet_name                   = string<br>    address_prefixes              = list(string)<br>    existing_nsg                  = optional(bool, false)<br>    existing_nsg_id               = optional(string, null)<br>    disable_nsg                   = optional(bool, false)<br>    disable_rt                    = optional(bool, false)<br>    existing_rt                   = optional(bool, false)<br>    existing_rt_id                = optional(string, null)<br>    disable_bgp_route_propagation = optional(bool)<br>    delegation = optional(map(object({<br>      name = optional(string)<br>      service_delegation = optional(object({<br>        name    = optional(string)<br>        actions = optional(list(string))<br>      }))<br>    })), {})<br>    nsg = map(object({<br>      security_rules = object({<br>        nsg_inbound_rules  = optional(list(list(string)), [])<br>        nsg_outbound_rules = optional(list(list(string)), [])<br>      })<br>    }))<br>    service_endpoints = list(string)<br>    route_table = map(object({<br>      routes = map(object({<br>        address_prefix         = string<br>        next_hop_type          = string<br>        next_hop_in_ip_address = optional(string)<br>      }))<br><br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags | `map(string)` | n/a | yes |
| <a name="input_vnet"></a> [vnet](#input\_vnet) | Virtual Networks object | <pre>object({<br>    vnet_name      = string<br>    address_prefix = list(string)<br>    dns_servers    = list(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_security_groups"></a> [network\_security\_groups](#output\_network\_security\_groups) | n/a |
| <a name="output_route_tables"></a> [route\_tables](#output\_route\_tables) | n/a |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | n/a |

## Usage

```hcl

module "vnet" {
  source              = "./modules/vnet"
  resource_group_name = "vnettest"
  location            = "westeurope"
  vnet = {
    vnet_name      = "test-vnet"
    address_prefix = ["10.240.0.0/16"]
    dns_servers    = []
  }
  subnets = {
    "web-subnet" = {
      subnet_name      = "web-subnet"
      address_prefixes = ["10.240.0.0/24"]
      delegation = {
        "testdelegation" = {
          name = "testdelegation"
          service_delegation = {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
          }
        }
      }
      nsg = {
        "nsg-web-subnet" = {
          security_rules = {
            nsg_inbound_rules = [
              ["Allow_Inbound_SSH", "1000", "Inbound", "Allow", "Tcp", "22", "*", "*"],
              ["Allow_Inbound_6443", "1001", "Inbound", "Allow", "Tcp", "6443", "*", "*"],

            ]
            nsg_outbound_rules = [
              ["Allow_Outbound_SSH", "4000", "Outbound", "Allow", "Tcp", "22", "*", "*"],
              ["Allow_Outbound_6443", "1002", "Outbound", "Allow", "Tcp", "644", "*", "*"],
            ]
          }
        }
      }
      disable_nsg                   = false
      disable_rt                    = false
      disable_bgp_route_propagation = false
      existing_rt                   = false
      existing_rt_id                = module.routetable.id
      existing_nsg                  = false
      #existing_nsg_id = module.network-security-group.network_security_group_id
      service_endpoints = ["Microsoft.Storage"]
      route_table = {
        "udr-web-subnet" = {
          routes = {
            "route-to-firewall" = {
              name                   = "route-to-firewall"
              address_prefix         = "10.200.0.0/24",
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.240.0.20"
            },
            "route-to-onprem" = {
              name                   = "route-to-onprem"
              address_prefix         = "10.200.1.0/24",
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.240.0.21"
            }
          }
        }
      }
    }
    "backend-subnet" = {
      subnet_name      = "backend-subnet"
      address_prefixes = ["10.240.1.0/24"]
      delegation       = {}
      nsg = {
        "nsg-backend-subnet" = {
          security_rules = {
            nsg_inbound_rules = [
              ["Allow_Inbound_SSH", "1000", "Inbound", "Allow", "Tcp", "22", "*", "*"],
              ["Allow_Inbound_6443", "1001", "Inbound", "Allow", "Tcp", "6443", "*", "*"],

            ]
            nsg_outbound_rules = []
          }
        }
      }
      disable_nsg                   = false
      disable_rt                    = false
      disable_bgp_route_propagation = false
      existing_rt                   = false
      existing_rt_id                = module.routetable.id
      existing_nsg                  = false
      #existing_nsg_id = module.network-security-group.network_security_group_id
      service_endpoints = []
      route_table = {
        "udr-backend" = {
          routes = {
            "to-firewall" = {
              name                   = "backend-to-firewall"
              address_prefix         = "10.200.0.0/24",
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.240.0.20"
            },
          }
        }
      }
    }
  }

  tags = {
    "Environment" = "Production"
  }
  depends_on = [module.network-security-group]
}

```