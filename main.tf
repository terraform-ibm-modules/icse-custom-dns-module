##############################################################################
# DNS Instance
##############################################################################

resource "ibm_resource_instance" "dns_service" {
  count             = var.use_data == true ? 0 : 1
  name              = "${var.prefix}-dns"
  resource_group_id = var.resource_group_id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
}

data "ibm_resource_instance" "dns_service" {
  count             = var.use_data == true ? 1 : 0
  name              = var.existing_instance_name
  resource_group_id = var.resource_group_id
}

locals {
  dns_id = (
    var.use_data == true
    ? data.ibm_resource_instance.dns_service[0].guid
    : ibm_resource_instance.dns_service[0].guid
  )
}

##############################################################################

##############################################################################
# DNS Zones
##############################################################################

module "dns_zone_map" {
  source         = "github.com/Cloud-Schematics/list-to-map"
  list           = var.dns_zones
  key_name_field = "url"
}

resource "ibm_dns_zone" "zone" {
  for_each    = module.dns_zone_map.value
  instance_id = local.dns_id
  name        = each.value.url
  description = each.value.description == null ? each.value.url : each.value.description
  label       = each.value.label == null ? replace(each.value.url, ".", "-") : each.value.label
}

##############################################################################

##############################################################################
# DNS Records
##############################################################################

module "dns_record_map" {
  source = "github.com/Cloud-Schematics/list-to-map"
  list   = var.dns_resource_records
}

resource "ibm_dns_resource_record" "record" {
  for_each    = module.dns_record_map.value
  instance_id = local.dns_id
  zone_id     = ibm_dns_zone.zone[each.value.url].zone_id
  name        = "${var.prefix}-${each.value.name}"
  rdata       = each.value.rdata
  type        = each.value.type
  ttl         = each.value.ttl
  preference  = each.value.preference
  priority    = each.value.priority
  port        = each.value.port
  protocol    = each.value.protocol
  service     = each.value.service
  weight      = each.value.weight
}

##############################################################################
