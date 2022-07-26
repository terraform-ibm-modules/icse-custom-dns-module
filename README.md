# IBM Cloud Solution Engineering VPC Custom DNS Module

Create a custom DNS service, zones, records. Users can also optionally create a custom DNS resolvers and custom DNS subnets on VPC.

---

## Table of Contents

1. [DNS Service](#dns-service)
2. [DNS Zones](#dns-zones)
3. [DNS Records](#dns-records)
4. [Custom Resolvers](#custom-resolvers)
5. [Module Variables](#module-variables)
6. [Module Outputs](#module-outputs)

---

## DNS Service

This module can either create a new DNS service instance or use an existing instance by providing the existing instance name.

---

## DNS Zones

Users can specify any number of DNS zones using the `dns_zones` variable. Resources in this list are converted to a map, allowing users to add or remove items from the list without unwanted changes.

```terraform
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
```

---

## DNS Records

Users can optionally add any number of DNS rexords. Resources in this list are converted to a map, allowing users to add or remove items from the list without unwanted changes.

```terraform
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
}
```

---

## Custom Resolvers

This module allows users to create multiple custom resolvers across multiple VPCs. Subnets in each VPC will be dynamically created for each custom resolver.

Subnet CIDR formula is `10.x.y0.0/24` where `x` is the zone (1, 2, or 3) and `y` is 1 plus the index of the custom resolver in the `var.custom_resolvers` list.

### Custom Resolver Variable

```terraform
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
}
```

---

## Module Variables

Name                   | Type                                                                                                                                                                                                                                                                                                                                                                             | Description                                                                                                                                                                                                                             | Sensitive | Default
---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------
TF_VERSION             | string                                                                                                                                                                                                                                                                                                                                                                           | The version of the Terraform engine that's used in the Schematics workspace.                                                                                                                                                            |           | 1.0
prefix                 | string                                                                                                                                                                                                                                                                                                                                                                           | A unique identifier for resources. Must begin with a lowercase letter and end with a lowerccase letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters. |           | 
region                 | string                                                                                                                                                                                                                                                                                                                                                                           | Region where DNS components will be provisioned To find your VPC region, use `ibmcloud is regions` command to find available regions.                                                                                                   |           | 
resource_group_id      | string                                                                                                                                                                                                                                                                                                                                                                           | ID of the resource group where DNS components will be provisioned                                                                                                                                                                       |           | null
use_data               | bool                                                                                                                                                                                                                                                                                                                                                                             | Get the data for an existing DNS instance. To use this feature a name must be provided using the `existing_instance_name` variable.                                                                                                     |           | false
existing_instance_name | string                                                                                                                                                                                                                                                                                                                                                                           | Instance name to retrieve from data. Only needed if `use_data` is set to `true`. Existing instance must be in the same resource group as `resource_group_id`.                                                                           |           | null
dns_zones              | list( object({ url = string description = optional(string) label = optional(string) }) )                                                                                                                                                                                                                                                                                         | List of DNS zones to add. At least one zone must be provisioned.                                                                                                                                                                        |           | 
dns_resource_records   | list( object({ url = string name = string rdata = string type = string ttl = optional(number) preference = optional(number) priority = optional(number) port = optional(number) protocol = optional(number) service = optional(number) weight = optional(number) }) )                                                                                                            | List describing DNS Records to add.                                                                                                                                                                                                     |           | []
custom_resolvers       | list( object({ vpc_name = string vpc_id = string zones = number enable = bool description = string resource_group_id = optional(string) use_manual_address_prefixes = optional(bool) tags = optional(list(string)) acl_id = optional(string) use_public_gateways = optional(bool) public_gateways = optional( object({ zone-1 = string zone-2 = string zone-3 = string }) ) }) ) | Map of custom DNS resolver deployments                                                                                                                                                                                                  |           | []

---

## Module Outputs


Name             | Description
---------------- | ------------------------------------------------------------
dns_id           | ID of the DNS instance used
dns_zones        | List of DNS zone names and IDs
dns_records      | List of DNS Record names, zone ids, and resource record ids.
custom_resolvers | List of custom resolvers
