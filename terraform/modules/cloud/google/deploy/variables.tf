variable "env" {}

variable "color" {
  default = "unknown"
}

variable "bootstrap_version" {}

variable "spot_nodes" {
  default = "0"
}

variable "static_nodes" {
  default = 0
}

variable "instance_type" {}

variable "epoch" {
  type = "map"
}

variable "depends_on" {
  default = []

  type = "list"
}

variable "image_name" {}

variable "vault_addr" {}

variable "vault_role" {}

variable "user_data_file" {
  default = "user_data.bash"
}

variable "zone" {}
variable "region" {}
variable "nodes" {}
variable "project" {}
