variable "vault_addr" {
  description = "Vault server URL address"
}

provider "aws" {
  version = "1.24"
  region  = "us-east-1"
  alias   = "us-east-1"
}

module "aws_deploy-test" {
  source            = "../../terraform/modules/cloud/aws/deploy"
  env               = "tf_test"
  bootstrap_version = "master"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 1

  spot_price    = "0.05"
  instance_type = "t3.medium"
  ami_name      = "epoch-ubuntu-16.04-*"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-builds/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.us-east-1"
  }
}
