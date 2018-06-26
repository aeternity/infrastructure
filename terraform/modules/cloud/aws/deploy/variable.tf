variable "env" {}

variable "color" {}

variable "spot_nodes" {
  default = "9"
}

variable "instance_type" {
  default = "m4.large"
}

variable "static_ip" {
  default = 1
}
