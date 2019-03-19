variable "vault_addr" {
  description = "Vault server URL address"
}

variable "bootstrap_version" {
  default = "mainnet_API_gateway_164307329"
}

module "aws_deploy-main-eu-west-2" {
  source            = "../modules/cloud/aws/deploy"
  env               = "main"
  bootstrap_version = "${var.bootstrap_version}"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"

  static_nodes      = 0
  spot_nodes        = 0
  gateway_nodes_min = 2
  gateway_nodes_max = 5

  spot_price       = "0.15"
  instance_type    = "t3.large"
  ami_name         = "aeternity-ubuntu-16.04-v1549009934"
  root_volume_size = 40

  aeternity = {
    package = "https://releases.ops.aeternity.com/aeternity-2.0.0-ubuntu-x86_64.tar.gz"
  }

  providers = {
    aws = "aws.eu-west-2"
  }
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
  gateway_nodes_max = 5

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

resource "aws_route53_health_check" "api-eu-west-2" {
  provider          = "aws.eu-west-2"
  fqdn              = "${module.aws_deploy-main-eu-west-2.gateway_lb_dns}"
  port              = 3013
  type              = "HTTP"
  resource_path     = "/v2/blocks/top"
  measure_latency   = false
  failure_threshold = "4"
  request_interval  = 30
}

resource "aws_route53_record" "api-eu-west-2" {
  provider = "aws.eu-west-2"
  zone_id  = "${var.dns_zone}"
  name     = "api.main.ops.aeternity.com"
  type     = "A"

  health_check_id = "${aws_route53_health_check.api-eu-west-2.id}"
  set_identifier  = "eu-west-2"

  alias {
    name                   = "${module.aws_deploy-main-eu-west-2.gateway_lb_dns}"
    zone_id                = "${module.aws_deploy-main-eu-west-2.gateway_lb_zone_id}"
    evaluate_target_health = true
  }

  latency_routing_policy = {
    region = "eu-west-2"
  }
}

resource "aws_route53_health_check" "api-us-west-2" {
  provider          = "aws.us-west-2"
  fqdn              = "${module.aws_deploy-main-us-west-2.gateway_lb_dns}"
  port              = 3013
  type              = "HTTP"
  resource_path     = "/v2/blocks/top"
  measure_latency   = false
  failure_threshold = "4"
  request_interval  = 30
}

resource "aws_route53_record" "api-us-west-2" {
  provider = "aws.us-west-2"
  zone_id  = "${var.dns_zone}"
  name     = "api.main.ops.aeternity.com"
  type     = "A"

  health_check_id = "${aws_route53_health_check.api-us-west-2.id}"
  set_identifier  = "us-west-2"

  alias {
    name                   = "${module.aws_deploy-main-us-west-2.gateway_lb_dns}"
    zone_id                = "${module.aws_deploy-main-us-west-2.gateway_lb_zone_id}"
    evaluate_target_health = true
  }

  latency_routing_policy = {
    region = "us-west-2"
  }
}
