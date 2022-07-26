##############################################################################
#                                                                            #
#                         Configuration Fail States                          #
#                                                                            #
##############################################################################

##############################################################################
# Fail if use data true and existing instance name not provided
##############################################################################

locals {
  CONFIGURATION_FAILURE_no_dns_instance_name = regex(
    "true",
    var.use_data == false
    ? true
    : var.existing_instance_name != null
  )
}

##############################################################################

##############################################################################
# Fail if url for record not found in dns zones
##############################################################################

locals {
  dns_zone_url_list = var.dns_zones.*.url
  CONFIGURATION_FAILURE_record_url_not_found = regex(
    true,
    (
      length(var.dns_resource_records) == 0
      ? true
      : length([
        for record in var.dns_resource_records :
        true if !contains(local.dns_zone_url_list, record.url)
      ]) == 0
    )
  )
}

##############################################################################
