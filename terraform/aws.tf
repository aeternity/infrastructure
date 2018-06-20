terraform {
    backend "s3" {
        bucket = "aeternity-terraform-states"
        key    = "aeternitystate.tfstate"
        region = "us-east-1"
        profile                 = "aeternity"
        shared_credentials_file = "/aws/credentials"
    }
}

#test stack
/*
#IRELAND
provider "aws" {
    version                 = "1.22"
    region                  = "eu-west-1"
    alias = "eu-west-1"
    shared_credentials_file = "/aws/credentials"
    profile                 = "aeternity"
}

#LONDON
provider "aws" {
    version                 = "1.22"
    region                  = "eu-west-2"
    alias = "eu-west-2"
    shared_credentials_file = "/aws/credentials"
    profile                 = "aeternity"
}

module "fleet" {
    source = "fleet"
    static = 1
    spot = "${var.spot_nodes}"

    env = "dev3"
    ami_id = "${var.ami_id}"
    subnets = "${var.subnets}"
    instance_type = "${var.instance_type}"

    providers = {
        aws = "aws.eu-west-1"
    }

    static_ip = 1
}

module "fleet-eu-west-2" {
    source = "fleet"
    static = 1
    spot = "${var.spot_nodes}"

    env = "dev3"
    ami_id = "${var.ami_id}"
    subnets = "${var.subnets}"
    instance_type = "${var.instance_type}"

    providers = {
        aws = "aws.eu-west-2"
    }

    static_ip = 1
}
*/
