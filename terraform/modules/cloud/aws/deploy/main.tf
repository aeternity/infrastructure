module "aws_vpc" {
  source = "vpc"
  env    = "${var.env}"
}

module "aws_fleet" {
  source            = "fleet"
  color             = "${var.color}"
  env               = "${var.env}"
  bootstrap_version = "${var.bootstrap_version}"
  vpc_id            = "${module.aws_vpc.vpc_id}"
  subnets           = "${module.aws_vpc.subnets}"
  spot_price        = "${var.spot_price}"
  instance_type     = "${var.instance_type}"
  ami_name          = "${var.ami_name}"
  root_volume_size  = "${var.root_volume_size}"
  vault_addr        = "${var.vault_addr}"
  vault_role        = "${var.vault_role}"

  spot_nodes   = "${var.spot_nodes}"
  static_nodes = "${var.static_nodes}"

  epoch = "${var.epoch}"
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
