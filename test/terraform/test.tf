variable "vault_addr" {
  description = "Vault server URL address"
}

variable "env_name" {
  default = "tf_test"
}

provider "aws" {
  version                 = "1.55"
  region                  = "ap-southeast-2"
  alias                   = "ap-southeast-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

module "aws_deploy-test" {
  source            = "../../terraform/modules/cloud/aws/deploy"
  env               = "${var.env_name}"
  bootstrap_version = "master"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 1

  spot_price    = "0.04"
  instance_type = "t3.medium"
  ami_name      = "aeternity-ubuntu-16.04-*"

  aeternity = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-node-builds/aeternity-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}
