module "aws_vpc" {
  source = "vpc"
  env    = "${var.env}"
}

module "aws_fleet" {
  source        = "fleet"
  color         = "${var.color}"
  env           = "${var.env}"
  vpc_id        = "${module.aws_vpc.vpc_id}"
  subnets       = "${module.aws_vpc.subnets}"
  spot_price    = "${var.spot_price}"
  instance_type = "${var.instance_type}"

  spot_nodes   = "${var.spot_nodes}"
  static_nodes = "${var.static_nodes}"

  epoch = "${var.epoch}"
}
