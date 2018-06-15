variable "static" {
    default = 0
}

variable "spot" {
    default = 0
}

variable "ami_id" {}
variable "env" {}
variable "instance_type" {
    default = "t2.micro"
}

variable "spot_price" {
    default = "1"
}


variable "subnets" {
    type = "list"
}
