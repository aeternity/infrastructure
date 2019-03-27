variable "env" {}

variable "availability_zones" {
  type = "map"

  default = {
    "us-west-2"      = "us-west-2a,us-west-2b,us-west-2c"
    "us-east-2"      = "us-east-2a,us-east-2b,us-east-2c"
    "eu-west-2"      = "eu-west-2a,eu-west-2b,eu-west-2c"
    "eu-central-1"   = "eu-central-1a,eu-central-1b,eu-central-1c"
    "eu-north-1"     = "eu-north-1a,eu-north-1b,eu-north-1c"
    "ap-southeast-1" = "ap-southeast-1a,ap-southeast-1b,ap-southeast-1c"
    "ap-southeast-2" = "ap-southeast-2a,ap-southeast-2b,ap-southeast-2c"
  }
}
