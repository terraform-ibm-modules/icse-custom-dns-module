#############################################################################
# DNS Variables
##############################################################################

output "dns_id" {
  description = "ID of the DNS instance used"
  value       = local.dns_id
}

output "dns_zones" {
  description = "List of DNS zone names and IDs"
  value = [
    for zone in module.dns_zone_map.value :
    {
      name = ibm_dns_zone.zone[zone.url].name
      id   = ibm_dns_zone.zone[zone.url].zone_id
    }
  ]
}

output "dns_records" {
  description = "List of DNS Record names, zone ids, and resource record ids."
  value = [
    for record in module.dns_record_map.value :
    {
      name               = ibm_dns_resource_record.record[record.name].name
      zone_id            = ibm_dns_resource_record.record[record.name].zone_id
      resource_record_id = ibm_dns_resource_record.record[record.name].resource_record_id
    }
  ]
}

##############################################################################

##############################################################################
# Custom Resolver Outputs
##############################################################################

output "custom_resolvers" {
  description = "List of custom resolvers"
  value = [
    for resolver in module.custom_resolver_map.value :
    {
      vpc_name           = resolver.vpc_name
      subnet_zone_list   = module.custom_resolver_subnets[resolver.vpc_name].subnet_zone_list
      custom_resolver_id = ibm_dns_custom_resolver.custom_resolver[resolver.vpc_name].custom_resolver_id
      locations          = ibm_dns_custom_resolver.custom_resolver[resolver.vpc_name].locations
    }
  ]
}

##############################################################################