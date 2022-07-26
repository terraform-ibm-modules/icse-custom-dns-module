##############################################################################
# Create map of resolvers
##############################################################################

module "custom_resolver_map" {
  source         = "github.com/Cloud-Schematics/list-to-map"
  list           = var.custom_resolvers
  key_name_field = "vpc_name"
}

##############################################################################

##############################################################################
# Create subnets for custom resolver
##############################################################################

module "custom_resolver_subnets" {
  source                              = "github.com/Cloud-Schematics/vpc-subnet-module"
  for_each                            = module.custom_resolver_map.value
  prefix                              = var.prefix
  region                              = var.region
  resource_group_id                   = each.value.resource_group_id == null ? var.resource_group_id : each.value.resource_group_id
  tags                                = each.value.tags
  vpc_id                              = each.value.vpc_id
  use_manual_address_prefixes         = each.value.use_manual_address_prefixes
  prepend_prefix_to_network_acl_names = false
  public_gateways = (
    each.value.public_gateways == null || each.value.use_public_gateways != true
    ? {
      zone-1 = null
      zone-2 = null
      zone-3 = null
    }
    : each.value.public_gateways
  )
  network_acls = [
    {
      name = "dns-acl"
      id   = each.value.acl_id
    }
  ]
  subnets = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => (
      zone > each.value.zones
      ? []
      : [
        {
          name           = "${var.prefix}-${each.value.vpc_name}-custom-dns-zone-${zone}"
          acl_name       = "dns-acl"
          public_gateway = each.value.use_public_gateways
          cidr = format(
            "10.%s.%s0.0/24",
            zone,
            1 + index(var.custom_resolvers.*.vpc_name, each.value.vpc_name)
          )
        }
      ]
    )
  }
}

##############################################################################

##############################################################################
# Custom DNS Resolver
##############################################################################

resource "ibm_dns_custom_resolver" "custom_resolver" {
  for_each          = module.custom_resolver_map.value
  name              = "${var.prefix}-${each.value.vpc_name}-custom-resolver"
  enabled           = each.value.enable
  instance_id       = local.dns_id
  high_availability = each.value.zones < 2 ? false : true

  dynamic "locations" {
    for_each = module.custom_resolver_subnets[each.value.vpc_name].subnet_zone_list
    content {
      subnet_crn = locations.value.crn
      enabled    = each.value.enable
    }
  }
}

##############################################################################