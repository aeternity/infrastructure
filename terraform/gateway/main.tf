variable "vault_addr" {
  description = "Vault server URL address"
}

variable "bootstrap_version" {
  default = "mainnet_API_gateway_164307329"
}

module "aws_deploy-main-us-west-2" {
  source            = "../modules/cloud/aws/deploy"
  env               = "main"
  bootstrap_version = "${var.bootstrap_version}"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes      = 0
  spot_nodes        = 0
  gateway_nodes_min = 2
  gateway_nodes_max = 30

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.0.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.us-west-2"
  }
}

module "aws_deploy-main-eu-north-1" {
  source            = "../modules/cloud/aws/deploy"
  env               = "main"
  bootstrap_version = "${var.bootstrap_version}"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes      = 0
  spot_nodes        = 0
  gateway_nodes_min = 2
  gateway_nodes_max = 30

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.0.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-north-1"
  }
}

module "aws_gateway" {
  providers = {
    aws = "aws.us-west-2"
  }

  source   = "../modules/cloud/aws/gateway"
  dns_zone = "${var.dns_zone}"

  loadbalancers = [
    "${module.aws_deploy-main-us-west-2.gateway_lb_dns}",
#    "${module.aws_deploy-main-eu-north-1.gateway_lb_dns}",
  ]

  loadbalancers_zones = [
    "${module.aws_deploy-main-us-west-2.gateway_lb_zone_id}",
#    "${module.aws_deploy-main-eu-north-1.gateway_lb_zone_id}",
  ]

  loadbalancers_regions = [
    "us-west-2",
#    "eu-north-1",
  ]

  api_dns = "api.main.ops.aeternity.com"
}
