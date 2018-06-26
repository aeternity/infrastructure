module "aws_vpc" {
  source = "vpc"
}

module "aws_fleet" {
  source        = "fleet"
  static        = 1
  spot          = "${var.spot_nodes}"
  color         = "${var.color}"
  env           = "${var.env}"
  vpc_id        = "${module.aws_vpc.vpc_id}"
  subnets       = "${module.aws_vpc.subnets}"
  instance_type = "${var.instance_type}"
  static_ip     = "${var.static_ip}"
}
