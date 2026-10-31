variable "domain_name" {
  description = "Domain the certification is issued for"
  type        = string
}

variable "zone_name" {
  description = "Existing route 53 housted zone"
  type        = string
}