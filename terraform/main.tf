terraform {
  backend "s3" {
    bucket = "aeternity-terraform-states"
    key    = "aeternitystate.tfstate"
    region = "us-east-1"
  }
}

variable "vault_addr" {
  description = "Vault server URL address"
}

provider "aws" {
  version = "1.24"
  region  = "ap-southeast-1"
  alias   = "ap-southeast-1"
}

provider "aws" {
  version = "1.24"
  region  = "eu-central-1"
  alias   = "eu-central-1"
}

provider "aws" {
  version = "1.24"
  region  = "eu-west-2"
  alias   = "eu-west-2"
}

provider "aws" {
  version                 = "1.24"
  region                  = "us-west-2"
  alias                   = "us-west-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

module "aws_deploy-ap-southeast-1" {
  source            = "modules/cloud/aws/deploy"
  env               = "uat"
  color             = "blue"
  bootstrap_version = "v1.2.1"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"
  user_data_file    = "user_data_uat.bash"

  static_nodes = 1
  spot_nodes   = 14

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1536651794"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-releases/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.ap-southeast-1"
  }
}

module "aws_deploy-eu-central-1" {
  source            = "modules/cloud/aws/deploy"
  env               = "uat"
  color             = "blue"
  bootstrap_version = "v1.2.1"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"
  user_data_file    = "user_data_uat.bash"

  static_nodes = 1
  spot_nodes   = 9

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1536651794"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-releases/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-central-1"
  }

  depends_on = ["${module.aws_deploy-ap-southeast-1.static_node_ips}"]
}

module "aws_deploy-us-west-2" {
  source            = "modules/cloud/aws/deploy"
  env               = "uat"
  color             = "green"
  bootstrap_version = "v1.2.1"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"
  user_data_file    = "user_data_uat.bash"

  static_nodes = 1
  spot_nodes   = 14

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1536651794"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-releases/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.us-west-2"
  }
}

module "aws_deploy-uat-eu-west-2" {
  source            = "modules/cloud/aws/deploy"
  env               = "uat"
  color             = "green"
  bootstrap_version = "v1.2.1"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"
  user_data_file    = "user_data_uat.bash"

  static_nodes = 1
  spot_nodes   = 9

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1536651794"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-releases/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }

  depends_on = ["${module.aws_deploy-us-west-2.static_node_ips}"]
}

module "aws_deploy-dev1-eu-west-2" {
  source            = "modules/cloud/aws/deploy"
  env               = "dev1"
  bootstrap_version = "v1.4"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"

  spot_nodes    = 10
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1541511248"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-builds/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}

module "aws_deploy-dev2-eu-west-2" {
  source            = "modules/cloud/aws/deploy"
  env               = "dev2"
  bootstrap_version = "master"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"

  spot_nodes    = 2
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1541511248"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-builds/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}

module "aws_deploy-integration-eu-west-2" {
  source            = "modules/cloud/aws/deploy"
  env               = "integration"
  bootstrap_version = "v1.4"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes  = 1
  spot_nodes    = 2
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1541511248"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-builds/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}

module "aws_deploy-fast_integration-eu-west-2" {
  source            = "modules/cloud/aws/deploy"
  env               = "fast_integration"
  bootstrap_version = "v1.4"
  vault_role        = "epoch-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes  = 1
  spot_nodes    = 2
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "epoch-ubuntu-16.04-v1541511248"

  epoch = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-epoch-builds/epoch-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}
