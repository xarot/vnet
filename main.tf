locals {
  nsgs = flatten([
    for subnet_key, subnet in var.subnets : [
      for nsg_key, nsg in subnet.nsg : {
        subnet_key      = subnet_key
        nsg_key         = nsg_key
        security_rules  = nsg.security_rules
        disable_nsg     = subnet["disable_nsg"]
        existing_nsg    = subnet["existing_nsg"]
        existing_nsg_id = subnet["existing_nsg_id"]
    }]
  ])

  route_tables = flatten([
    for subnet_key, subnet in var.subnets : [
      for route_table_key, route_table in subnet.route_table : {
        subnet_key                    = subnet_key
        route_table_key               = route_table_key
        disable_rt                    = subnet["disable_rt"]
        disable_bgp_route_propagation = subnet["disable_bgp_route_propagation"]
        routes                        = route_table["routes"]
        existing_rt                   = subnet["existing_rt"]
        existing_rt_id                = subnet["existing_rt_id"]
    }]
  ])
}

data "azurerm_resource_group" "vnet_resource_group" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet.vnet_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.vnet_resource_group.name
  address_space       = var.vnet.address_prefix
  dns_servers         = var.vnet.dns_servers
  depends_on = [
    data.azurerm_resource_group.vnet_resource_group
  ]
}

resource "azurerm_subnet" "snet" {
  for_each             = var.subnets
  resource_group_name  = data.azurerm_resource_group.vnet_resource_group.name
  name                 = each.value.subnet_name
  virtual_network_name = var.vnet.vnet_name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
  dynamic "delegation" {
    for_each = each.value.delegation
    content {
      name = delegation.value.name
      service_delegation {
        name    = lookup(delegation.value.service_delegation, "name", null)
        actions = lookup(delegation.value.service_delegation, "actions", null)
      }
    }
  }
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_route_table" "rt" {
  for_each = {
    for route_table in local.route_tables : route_table.route_table_key => route_table
    if route_table.disable_rt != true && route_table.existing_rt == false
  }
  name                          = each.key
  resource_group_name           = data.azurerm_resource_group.vnet_resource_group.name
  location                      = var.location
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation
  tags                          = var.tags
  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      name                   = route.key
      address_prefix         = lookup(route.value, "address_prefix", null)
      next_hop_type          = lookup(route.value, "next_hop_type", null)
      next_hop_in_ip_address = lookup(route.value, "next_hop_type") == "VirtualAppliance" ? lookup(route.value, "next_hop_in_ip_address") : null
    }
  }
}

resource "azurerm_subnet_route_table_association" "rt-association" {
  for_each = {
    for route_table in local.route_tables : route_table.route_table_key => route_table
    if route_table.disable_rt != true && route_table.existing_rt == false
  }
  subnet_id      = azurerm_subnet.snet[each.value.subnet_key].id
  route_table_id = azurerm_route_table.rt[each.key].id
}

resource "azurerm_subnet_route_table_association" "rt-association-existing" {
  for_each = {
    for route_table in local.route_tables : route_table.route_table_key => route_table
    if route_table.existing_rt == true && route_table.disable_rt != true
  }
  subnet_id      = azurerm_subnet.snet[each.value.subnet_key].id
  route_table_id = each.value.existing_rt_id
}

resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for nsg in local.nsgs : nsg.nsg_key => nsg
    if nsg.disable_nsg != true
  }
  name                = each.key
  resource_group_name = data.azurerm_resource_group.vnet_resource_group.name
  location            = var.location
  tags                = var.tags
  dynamic "security_rule" {
    for_each = concat(lookup(each.value.security_rules, "nsg_inbound_rules", []), lookup(each.value.security_rules, "nsg_outbound_rules", []))
    content {
      name                       = security_rule.value[0] == "" ? "Default" : security_rule.value[0]
      priority                   = security_rule.value[1] == "" ? "1000" : security_rule.value[1]
      direction                  = security_rule.value[2] == "" ? "Inbound" : security_rule.value[2]
      access                     = security_rule.value[3] == "" ? "Allow" : security_rule.value[3]
      protocol                   = security_rule.value[4] == "" ? "Tcp" : security_rule.value[4]
      source_port_range          = "*"
      destination_port_range     = security_rule.value[5] == "" ? "*" : security_rule.value[5]
      source_address_prefix      = security_rule.value[6] == "" ? element(each.value.subnet_address_prefixes, 0) : security_rule.value[6]
      destination_address_prefix = security_rule.value[7] == "" ? element(each.value.subnet_address_prefixes, 0) : security_rule.value[7]
      description                = "${security_rule.value[2]}_Port_${security_rule.value[5]}"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  for_each = {
    for nsg in local.nsgs : nsg.nsg_key => nsg
    if nsg.disable_nsg != true && nsg.existing_nsg == false
  }
  subnet_id                 = azurerm_subnet.snet[each.value.subnet_key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_subnet_network_security_group_association" "nsg-association-existing" {
  for_each = {
    for nsg in local.nsgs : nsg.nsg_key => nsg
    if nsg.existing_nsg == true && nsg.disable_nsg == true
  }
  subnet_id                 = azurerm_subnet.snet[each.value.subnet_key].id
  network_security_group_id = each.value.existing_nsg_id
}