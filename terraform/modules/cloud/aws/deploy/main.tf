module "aws_vpc" {
  source = "vpc"
  env    = "${var.env}"
}

module "aws_fleet" {
  source              = "fleet"
  color               = "${var.color}"
  env                 = "${var.env}"
  bootstrap_version   = "${var.bootstrap_version}"
  vpc_id              = "${module.aws_vpc.vpc_id}"
  subnets             = "${module.aws_vpc.subnets}"
  spot_price          = "${var.spot_price}"
  instance_type       = "${var.instance_type}"
  ami_name            = "${var.ami_name}"
  root_volume_size    = "${var.root_volume_size}"
  vault_addr          = "${var.vault_addr}"
  vault_role          = "${var.vault_role}"
  user_data_file      = "${var.user_data_file}"
  spot_user_data_file = "${var.user_data_file}"

  spot_nodes        = "${var.spot_nodes}"
  static_nodes      = "${var.static_nodes}"
  gateway_nodes_min = "${var.gateway_nodes_min}"
  gateway_nodes_max = "${var.gateway_nodes_max}"
  dns_zone          = "${var.dns_zone}"
  gateway_dns       = "${var.gateway_dns}"
  envid             = "${var.envid}"

  additional_storage      = "${var.additional_storage}"
  additional_storage_size = "${var.additional_storage_size}"

  aeternity = "${var.aeternity}"
}

output "gateway_lb_dns" {
  value = "${module.aws_fleet.gateway_lb_dns}"
}

output "gateway_lb_zone_id" {
  value = "${module.aws_fleet.gateway_lb_zone_id}"
}

# Module to module depens_on workaround
# See https://github.com/hashicorp/terraform/issues/1178#issuecomment-105613781
# See https://github.com/hashicorp/terraform/issues/10462#issuecomment-285751349
# See https://github.com/hashicorp/terraform/issues/17101
resource "null_resource" "dummy_dependency" {
  triggers {
    depends_on = "${join(",", var.depends_on)}"
  }
}

output "static_node_ips" {
  value = "${module.aws_fleet.static_node_ips}"
}
