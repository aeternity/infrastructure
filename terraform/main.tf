terraform {
    backend "s3" {
        bucket = "aeternity-terraform-states"
        key    = "aeternitystate.tfstate"
        region = "us-east-1"
    }
}

provider "aws" {
    version                 = "1.22"
    region                  = "ap-southeast-1"
    alias = "ap-southeast-1"
}

module "fleet" {
    source = "fleet/aws"
    static = 1
    spot = "${var.spot_nodes}"
    color = "blue"
    env = "uat"
    ami_id = "${var.ami_id}"
    subnets = "${var.subnets}"
    instance_type = "${var.instance_type}"

    providers = {
        aws = "aws.ap-southeast-1"
    }

    static_ip = 0
}
