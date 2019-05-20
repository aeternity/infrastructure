variable "vault_addr" {
  description = "Vault server URL address"
}

module "aws_deploy-main-ap-southeast-1" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "main"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 10
  spot_nodes   = 0

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  additional_storage      = 1
  additional_storage_size = 30

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.5.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.ap-southeast-1"
  }
}

module "aws_deploy-main-eu-north-1" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "main"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 10
  spot_nodes   = 0

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  additional_storage      = 1
  additional_storage_size = 30

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.5.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-north-1"
  }

  depends_on = ["${module.aws_deploy-ap-southeast-1.static_node_ips}"]
}

module "aws_deploy-main-us-west-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "main"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 10
  spot_nodes   = 0

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  additional_storage      = 1
  additional_storage_size = 30

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.5.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.us-west-2"
  }
}

module "aws_deploy-main-us-east-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "main"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 10
  spot_nodes   = 0

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  additional_storage      = 1
  additional_storage_size = 30

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.5.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.us-east-2"
  }
}

module "aws_deploy-ap-southeast-1" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "uat"
  color             = "blue"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 14

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-3.0.0-rc.1-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.ap-southeast-1"
  }
}

module "aws_deploy-eu-central-1" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "uat"
  color             = "blue"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 9

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-3.0.0-rc.1-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-central-1"
  }

  depends_on = ["${module.aws_deploy-ap-southeast-1.static_node_ips}"]
}

module "aws_deploy-us-west-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "uat"
  color             = "green"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 14

  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-3.0.0-rc.1-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.us-west-2"
  }
}

module "aws_deploy-uat-eu-north-1" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "uat"
  color             = "green"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes = 1
  spot_nodes   = 9

  spot_price    = "0.07"
  instance_type = "m5.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-3.0.0-rc.1-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-north-1"
  }

  depends_on = ["${module.aws_deploy-us-west-2.static_node_ips}"]
}

module "aws_deploy-dev1-eu-west-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "dev1"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  spot_nodes       = 3
  spot_price       = "0.125"
  instance_type    = "m4.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 20

  aeternity = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-node-builds/aeternity-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}

module "aws_deploy-dev2-eu-west-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "dev2"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  spot_nodes    = 2
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-node-builds/aeternity-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}

module "aws_deploy-integration-eu-west-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "integration"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes  = 1
  spot_nodes    = 2
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-node-builds/aeternity-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}

module "aws_deploy-next-eu-west-2" {
  source            = "github.com/aeternity/terraform-aws-aenode-deploy?ref=v1.0.0"
  env               = "next"
  bootstrap_version = "v2.0.1"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes  = 1
  spot_nodes    = 2
  spot_price    = "0.125"
  instance_type = "m4.large"
  ami_name      = "aeternity-ubuntu-16.04-v1549009934"

  aeternity = {
    package = "https://s3.eu-central-1.amazonaws.com/aeternity-node-builds/aeternity-latest-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
}
