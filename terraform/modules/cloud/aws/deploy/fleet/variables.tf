variable "static_nodes" {}

variable "spot_nodes" {}

variable "color" {}

variable "env" {}

variable "bootstrap_version" {}

variable "instance_type" {}

variable "spot_price" {}

variable "vpc_id" {}

variable "subnets" {
  type = "list"
}

variable "epoch" {
  type = "map"
}

variable "ami_name" {}

variable "vault_addr" {}

variable "vault_role" {}

variable "user_data_file" {}
