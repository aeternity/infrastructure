variable "vault_addr" {
  description = "Vault server URL address"
}

variable "env_name" {
  default = "test"
}

variable "envid" {
  description = "Unique test environment identifier to prevent collisions."
}

variable "bootstrap_version" {
  default = "master"
}

provider "aws" {
  region                  = "ap-southeast-2"
  alias                   = "ap-southeast-2"
  shared_credentials_file = "/aws/credentials"
  profile                 = "aeternity"
}

module "aws_deploy-test-aenode" {
  source = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v3.0.1"
  env    = var.env_name

  static_nodes = 1
  spot_nodes   = 1

  instance_types = ["t3.large"]
  ami_name       = "aeternity-ubuntu-18.04-*"

  additional_storage      = true
  additional_storage_size = 5

  tags = {
    env   = var.env_name
    envid = var.envid
    role  = "aenode"
  }

  config_tags = {
    bootstrap_version = var.bootstrap_version
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    node_config       = "secret/aenode/config/${var.env_name}"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}

module "aws_deploy-test-aemdw" {
  source = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v3.0.1"
  env    = var.env_name

  static_nodes = 1
  spot_nodes   = 1

  instance_types = ["t3.large"]
  ami_name       = "aeternity-ubuntu-18.04-*"

  additional_storage      = true
  additional_storage_size = 5

  tags = {
    env   = var.env_name
    envid = var.envid
    role  = "aemdw"
  }

  config_tags = {
    bootstrap_version = var.bootstrap_version
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    node_config       = "secret/aenode/config/${var.env_name}"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}
