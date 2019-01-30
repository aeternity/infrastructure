variable "vault_addr" {
  description = "Vault server URL address"
}

provider "aws" {
  version = "1.55"
  region  = "eu-west-3"
  alias   = "eu-west-3"
}

module "aws_deploy-test" {
  source            = "../../terraform/modules/cloud/aws/deploy"
  env               = "tf_test"
  bootstrap_version = "master"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 1

  spot_price    = "0.08"
  instance_type = "t3.medium"
  ami_name      = "aeternity-ubuntu-16.04-*"

  aeternity = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-node-builds/aeternity-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-3"
  }
}
