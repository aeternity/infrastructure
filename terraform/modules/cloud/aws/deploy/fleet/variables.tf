variable "static_nodes" {}

variable "spot_nodes" {}

variable "color" {}

variable "env" {}

variable "instance_type" {}

variable "spot_price" {}

variable "vpc_id" {}

variable "subnets" {
  type = "list"
}

variable "epoch" {
  type = "map"
}
