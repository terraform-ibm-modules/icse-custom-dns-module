##############################################################################
# Account Variables
##############################################################################

variable "TF_VERSION" {
  default     = "1.0"
  type        = string
  description = "The version of the Terraform engine that's used in the Schematics workspace."
}

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a lowercase letter and end with a lowerccase letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string

  validation {
    error_message = "Prefix must begin with a lowercase letter and contain only lowercase letters, numbers, and - characters. Prefixes must end with a lowercase letter or number and be 16 or fewer characters."
    condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix)) && length(var.prefix) <= 16
  }
}

variable "region" {
  description = "Region where DNS components will be provisioned To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group where DNS components will be provisioned"
  type        = string
  default     = null
}

##############################################################################

##############################################################################
# DNS Variables
##############################################################################

variable "use_data" {
  description = "Get the data for an existing DNS instance. To use this feature a name must be provided using the `existing_instance_name` variable."
  type        = bool
  default     = false
}

variable "existing_instance_name" {
  description = "Instance name to retrieve from data. Only needed if `use_data` is set to `true`. Existing instance must be in the same resource group as `resource_group_id`."
  type        = string
  default     = null
}

##############################################################################

##############################################################################
# DNS Zones Variable
##############################################################################

variable "dns_zones" {
  description = "List of DNS zones to add. At least one zone must be provisioned."
  type = list(
    object({
      url         = string           # URL for the zone
      description = optional(string) # Description of DNS Zone if not used will default to zone url
      label       = optional(string) # Label of DNS Zone if not used will default to zone url
    })
  )

  validation {
    error_message = "At least one DNS zone must be provided."
    condition     = length(var.dns_zones) > 0
  }
}

##############################################################################

##############################################################################
# DNS Record Variables
##############################################################################

variable "dns_resource_records" {
  description = "List describing DNS Records to add."
  type = list(
    object({
      url        = string           # Must exist in `var.dns_zones`
      name       = string           # Name of the record
      rdata      = string           # DNA reource record data
      type       = string           # Type of record. Can be `A`, `AAAA`, `CNAME`, `PTR`, `TXT`, `MX` or `SRV`
      ttl        = optional(number) # time till live
      preference = optional(number) # Required for MX records
      priority   = optional(number) # Required for SRV records
      port       = optional(number) # required for SRV records
      protocol   = optional(number) # required for SRV records
      service    = optional(number) # required for SRV records
      weight     = optional(number) # required for SRV records
    })
  )

  default = []

  validation {
    error_message = "Records for DNS Resource types can only be Can be `A`, `AAAA`, `CNAME`, `PTR`, `TXT`, `MX` or `SRV`."
    condition = (
      length(var.dns_resource_records) == 0
      ? true
      : length([
        for record in var.dns_resource_records :
        true if !contains(["A", "AAAA", "CNAME", "PTR", "TXT", "MX", "SRV"], record.type)
      ]) == 0
    )
  }
}

##############################################################################

##############################################################################
# VPC Variables
##############################################################################

variable "custom_resolvers" {
  description = "Map of custom DNS resolver deployments"
  type = list(
    object({
      vpc_name                    = string                 # name of the custom resolver
      vpc_id                      = string                 # ID fo the VPC where the custom resolver will be created
      zones                       = number                 # number of zones for resolver, can be 1, 2, or 3
      enable                      = bool                   # toggle on/off
      description                 = string                 # plaintext description
      resource_group_id           = optional(string)       # use only if the resolver is provisioned in a different rg
      use_manual_address_prefixes = optional(bool)         # Set to true if using manual address prefixes
      tags                        = optional(list(string)) # tags to use for created VPC resources
      acl_id                      = optional(string)       # acl to use for custom resolver subnets
      use_public_gateways         = optional(bool)         # use public gateways for created subnets
      ##############################################################################
      # gateways will only be added to subnets if an ID for that subnet's zone 
      # is passed using `public_gateways`. To ignore, set `public_gateways` to
      # null
      ##############################################################################
      public_gateways = optional(
        object({
          zone-1 = string
          zone-2 = string
          zone-3 = string
        })
      )
    })
  )
  default = []

  validation {
    error_message = "Custom resolvers can only be created in 1, 2, or 3 zones."
    condition = length(var.custom_resolvers) == 0 ? true : length([
      for resolver in var.custom_resolvers :
      true if resolver.zones < 1 || resolver.zones > 3
    ]) == 0
  }

  validation {
    error_message = "Custom resolvers must each have a unique VPC id."
    condition     = length(var.custom_resolvers) == 0 ? true : length(var.custom_resolvers.*.vpc_id) == length(distinct(var.custom_resolvers.*.vpc_id))
  }
}

##############################################################################