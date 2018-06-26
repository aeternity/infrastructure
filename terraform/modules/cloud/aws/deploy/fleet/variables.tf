variable "static_nodes" {
  default = 1
}

variable "spot_nodes" {
  default = 9
}

variable "color" {}

variable "env" {}

variable "instance_type" {
  default = "t2.micro"
}

variable "spot_price" {
  default = "1"
}

variable "vpc_id" {}

variable "subnets" {
  type = "list"
}
