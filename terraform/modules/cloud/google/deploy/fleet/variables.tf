variable "static_nodes" {}
variable "image_name" {}
variable "instance_type" {}
variable "env" {}
variable "network_name" {}
variable "zone" {}
variable "region" {}
variable "vault_addr" {}

variable "vault_role" {}

variable "user_data_file" {}

variable "bootstrap_version" {}

variable "epoch" {
  type = "map"
}

variable "nodes" {}
variable "color" {}
variable "project" {}
