data "aws_region" "current" {}

# Hardcode image to prevent Static node to be rotated on new image version releases
data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  owners = ["self"]
}

resource "aws_instance" "static_node" {
  count                = "${var.static_nodes}"
  ami                  = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "epoch-node"

  tags {
    Name  = "ae-${var.env}-static-node"
    env   = "${var.env}"
    role  = "epoch"
    color = "${var.color}"
    kind  = "seed"
  }

  user_data = "${module.user_data.user_data}"

  subnet_id              = "${element( var.subnets, 1)}"
  vpc_security_group_ids = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]
}

resource "aws_launch_configuration" "spot" {
  name_prefix          = "ae-${var.env}-spot-nodes_"
  iam_instance_profile = "epoch-node"
  image_id             = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  spot_price           = "${var.spot_price}"
  security_groups      = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${module.user_data.user_data}"
}

module "user_data" {
  source = "../../../../user_data/"
  region            = "${data.aws_region.current.name}"
  env               = "${var.env}"
  bootstrap_version = "${var.bootstrap_version}"
  epoch_package     = "${var.epoch["package"]}"
  vault_addr        = "${var.vault_addr}"
  vault_role        = "${var.vault_role}"
}

resource "aws_autoscaling_group" "spot_fleet" {
  name                 = "ae-${var.env}-spot-nodes"
  min_size             = "${var.spot_nodes}"
  max_size             = "${var.spot_nodes}"
  launch_configuration = "${aws_launch_configuration.spot.id}"
  vpc_zone_identifier  = ["${var.subnets}"]

  #  suspended_processes  = ["Terminate"]
  termination_policies = ["OldestInstance"]

  tags = [
    {
      key                 = "Name"
      value               = "ae-${var.env}-nodes"
      propagate_at_launch = true
    },
    {
      key                 = "env"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "role"
      value               = "epoch"
      propagate_at_launch = true
    },
    {
      key                 = "color"
      value               = "${var.color}"
      propagate_at_launch = true
    },
  ]
}

output "static_node_ips" {
  value = "${aws_eip_association.ip_associate.*.public_ip}"
}
