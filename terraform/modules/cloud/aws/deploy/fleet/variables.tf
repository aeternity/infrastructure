variable "static_nodes" {}

variable "spot_nodes" {}

variable "additional_storage" {
  default = 0
}

variable "additional_storage_size" {}

variable "gateway_nodes_min" {}

variable "gateway_nodes_max" {}

variable "color" {}

variable "env" {}

variable "envid" {
  default = ""
}

variable "bootstrap_version" {}

variable "instance_type" {}

variable "spot_price" {}

variable "vpc_id" {}

variable "subnets" {
  type = "list"
}

variable "aeternity" {
  type = "map"
}

variable "ami_name" {}

variable "vault_addr" {}

variable "vault_role" {}

variable "root_volume_size" {}

variable "dns_zone" {
  default = ""
}

variable "gateway_dns" {
  default = ""
}

variable "user_data_file" {}

variable "spot_user_data_file" {}
