provider "aws" {
  version                 = "1.22"
  region                  = "eu-west-1"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

module "fleet" {
    source = "fleet"
    static = 1
    spot = 1
    ami_id = "${var.ami_id}"
    env = "spot"
    subnets = ["subnet-aa989ef1","subnet-25d11543","subnet-0c7bb044"]
}
