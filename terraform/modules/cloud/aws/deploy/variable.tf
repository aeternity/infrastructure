variable "env" {}

variable "envid" {
  default = ""
}

variable "color" {
  default = "unknown"
}

variable "bootstrap_version" {}

variable "spot_nodes" {
  default = 0
}

variable "gateway_nodes_min" {
  default = 0
}

variable "gateway_nodes_max" {
  default = 0
}

variable "additional_storage" {
  default = 0
}

variable "additional_storage_size" {
  default = 0
}

variable "static_nodes" {
  default = 0
}

variable "instance_type" {}

variable "spot_price" {}

variable "aeternity" {
  type = "map"
}

# Module to module depens_on workaround
# See https://github.com/hashicorp/terraform/issues/1178#issuecomment-105613781
# See https://github.com/hashicorp/terraform/issues/10462#issuecomment-285751349
# See https://github.com/hashicorp/terraform/issues/17101
variable "depends_on" {
  default = []

  type = "list"
}

variable "ami_name" {}

variable "vault_addr" {}

variable "vault_role" {}

# Keep 8GB as default root volume size, that is the same if no parameter is used
variable "root_volume_size" {
  description = "Number of gigabytes. Default to 8."
  default     = 8
}

variable "dns_zone" {
  default = ""
}

variable "gateway_dns" {
  default = ""
}

variable "user_data_file" {
  default = "user_data.bash"
}

variable "spot_user_data_file" {
  default = "user_data.bash"
}
