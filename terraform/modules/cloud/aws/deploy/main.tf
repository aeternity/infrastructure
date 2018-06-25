module "aws_vpc" {
  source = "vpc"
}

module "aws_config" {
  source = "../config"
}

module "aws_fleet" {
  source        = "fleet"
  static        = 1
  spot          = "${module.aws_config.spot_nodes}"
  color         = "${var.color}"
  env           = "${var.env}"
  vpc_id        = "${module.aws_vpc.vpc_id}"
  subnets       = "${module.aws_vpc.subnets}"
  instance_type = "${module.aws_config.instance_type}"
  static_ip = 0
}
