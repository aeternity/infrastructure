terraform {
    backend "s3" {
        bucket = "aeternity-terraform-states"
        key    = "aeternity-test-state.tfstate"
        region = "us-east-1"
#        profile                 = "aeternity"
#        shared_credentials_file = "/aws/credentials"
    }
}
#IRELAND
provider "aws" {
    version                 = "1.22"
    region                  = "eu-west-1"
    alias = "eu-west-1"
#  shared_credentials_file = "/aws/credentials"
#  profile                 = "aeternity"
}

#LONDON

provider "aws" {
    version                 = "1.22"
    region                  = "eu-west-2"
    alias = "eu-west-2"
#  shared_credentials_file = "/aws/credentials"
#  profile                 = "aeternity"
}

module "fleet" {
    #    provider = "aws.eu-west-1"
#    provider = "aws.eu-west-2"
    source = "fleet"
    static = 1
    spot = 1
    ami_id = "ami-5ea58927"
    env = "dev3"
    subnets = ["subnet-aa989ef1","subnet-25d11543","subnet-0c7bb044"]
    providers = {
        aws = "aws.eu-west-1"
    }
}

module "fleet-eu-west-2" {
#    provider = "aws.eu-west-2"
    source = "fleet"
    static = 1
    spot = 1
    ami_id = "ami-a133ddc6"
    env = "dev3"
    subnets = ["subnet-5979d830","subnet-a79d83dc","subnet-7cf1de31"]
    providers = {
        aws = "aws.eu-west-2"
    }

}
