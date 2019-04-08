terraform {
  backend "s3" {
    bucket         = "aeternity-terraform-states"
    key            = "aeternity-gateway-state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  version = "1.55"
  region  = "us-west-2"
  alias   = "us-west-2"
}

provider "aws" {
  version = "1.55"
  region  = "us-east-1"
  alias   = "us-east-1"
}

provider "aws" {
  version = "1.55"
  region  = "eu-north-1"
  alias   = "eu-north-1"
}
