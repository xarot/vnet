output "subnets" {
  value = { for subnet_name, subnet in azurerm_subnet.snet : subnet_name => {
    subnet_name : subnet_name
    subnet_id : subnet.id }
  }
}

output "network_security_groups" {
  value = { for nsg_name, nsg in azurerm_network_security_group.nsg : nsg_name => {
    nsg_name : nsg_name
    nsg_id : nsg.id }
  }
}

output "route_tables" {
  value = { for rt_name, rt in azurerm_route_table.rt : rt_name => {
    rt_name : rt_name
    rt_id : rt.id }
  }
}

