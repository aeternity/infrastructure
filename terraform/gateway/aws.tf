terraform {
  backend "s3" {
    bucket                  = "aeternity-terraform-states"
    key                     = "aeternity-gateway-state.tfstate"
    region                  = "us-east-1"
    dynamodb_table          = "terraform-lock-table"
    shared_credentials_file = "/aws/credentials"
    profile                 = "aeternity"
  }
}

provider "aws" {
  version                 = "1.55"
  region                  = "us-west-2"
  alias                   = "us-west-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

provider "aws" {
  version                 = "1.55"
  region                  = "eu-west-2"
  alias                   = "eu-west-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

provider "aws" {
  version                 = "1.55"
  region                  = "ap-southeast-2"
  alias                   = "ap-southeast-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}
