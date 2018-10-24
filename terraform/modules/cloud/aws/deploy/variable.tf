variable "env" {}

variable "color" {
  default = "unknown"
}

variable "bootstrap_version" {}

variable "spot_nodes" {}

variable "static_nodes" {
  default = 0
}

variable "instance_type" {}

variable "spot_price" {}

variable "epoch" {
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
