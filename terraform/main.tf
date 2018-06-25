terraform {
  backend "s3" {
    bucket                  = "aeternity-terraform-states"
    key                     = "aeternitystate.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = "/aws/credentials"
    profile                 = "aeternity"
  }
}

provider "aws" {
  version                 = "1.24"
  region                  = "ap-southeast-1"
  alias                   = "ap-southeast-1"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

module "aws_deploy" {
  source = "modules/cloud/aws/deploy"
  env    = "uat"
  color  = "blue"

  providers = {
    aws = "aws.ap-southeast-1"
  }
}