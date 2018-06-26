module "aws_vpc" {
  source = "vpc"
}

module "aws_fleet" {
  source        = "fleet"
  color         = "${var.color}"
  env           = "${var.env}"
  vpc_id        = "${module.aws_vpc.vpc_id}"
  subnets       = "${module.aws_vpc.subnets}"
  instance_type = "${var.instance_type}"

  spot_nodes   = "${var.spot_nodes}"
  static_nodes = "${var.static_nodes}"
}
