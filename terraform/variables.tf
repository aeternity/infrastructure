variable  "instance_type" {
    default = "m4.large"
}

variable "spot_nodes" {
    default = "9"
}
variable "ami_id" {
    type ="map"
    default = {
        "eu-west-1" = "ami-5ea58927"
        "eu-west-2" = "ami-a133ddc6"
        "ap-southeast-1" = "ami-7f461803"
    }
}
variable "subnets" {
    type = "map"
    default = {
        "eu-west-1" = "subnet-aa989ef1,subnet-25d11543,subnet-0c7bb044"
        "eu-west-2" = "subnet-5979d830,subnet-a79d83dc,subnet-7cf1de31"
        "ap-southeast-1" = "subnet-ed9997ab,subnet-0b0a7e42,subnet-9e7135f9"
    }
}
