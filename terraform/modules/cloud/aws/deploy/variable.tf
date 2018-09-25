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
