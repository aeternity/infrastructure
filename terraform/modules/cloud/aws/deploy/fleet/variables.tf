variable "static_nodes" {}

variable "spot_nodes" {}

variable "gateway_nodes_min" {}

variable "gateway_nodes_max" {}

variable "color" {}

variable "env" {}

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
