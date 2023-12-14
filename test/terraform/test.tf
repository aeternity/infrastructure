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
}

module "test-aenode-1804" {
  source = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v3.1.0"
  env    = var.env_name

  static_nodes = 1
  spot_nodes   = 1

  instance_type  = "t3.large"
  instance_types = ["t3.large"]
  ami_name       = "aeternity-ubuntu-18.04-*"

  additional_storage      = true
  additional_storage_size = 5

  tags = {
    env   = var.env_name
    envid = var.envid
    role  = "aenode"
    kind  = "1804"
  }

  config_tags = {
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    bootstrap_version = var.bootstrap_version
    bootstrap_config  = "secret/aenode/config/${var.env_name}"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}

module "test-aenode-2204" {
  source = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v3.1.0"
  env    = var.env_name

  static_nodes = 1
  spot_nodes   = 1

  instance_type  = "t3.large"
  instance_types = ["t3.large"]
  ami_name       = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

  additional_storage      = true
  additional_storage_size = 5

  tags = {
    env   = var.env_name
    envid = var.envid
    role  = "aenode"
    kind  = "2204"
  }

  config_tags = {
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    bootstrap_version = var.bootstrap_version
    bootstrap_config  = "secret/aenode/config/${var.env_name}"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}

module "test-aemdw-1804" {
  source = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v3.1.0"
  env    = var.env_name

  static_nodes = 1
  spot_nodes   = 0

  instance_type  = "t3.large"
  instance_types = ["t3.large"]
  ami_name       = "aeternity-ubuntu-18.04-*"

  additional_storage      = true
  additional_storage_size = 5

  enable_mdw = true

  tags = {
    env   = var.env_name
    envid = var.envid
    role  = "aemdw"
    kind  = "1804"
  }

  config_tags = {
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    bootstrap_version = var.bootstrap_version
    bootstrap_config  = "secret/aenode/config/${var.env_name}"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}

module "test-aemdw-2204" {
  source = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v3.1.0"
  env    = var.env_name

  static_nodes = 1
  spot_nodes   = 0

  instance_type  = "t3.large"
  instance_types = ["t3.large"]
  ami_name       = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

  additional_storage      = true
  additional_storage_size = 5

  enable_mdw = true

  tags = {
    env   = var.env_name
    envid = var.envid
    role  = "aemdw"
    kind  = "2204"
  }

  config_tags = {
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    bootstrap_version = var.bootstrap_version
    bootstrap_config  = "secret/aenode/config/${var.env_name}"
  }

  providers = {
    aws = "aws.ap-southeast-2"
  }
}
