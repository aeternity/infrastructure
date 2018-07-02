data "aws_region" "current" {}

# Hardcode image to prevent Static node to be rotated on new image version releases
data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["epoch-ubuntu-16.04-v1532694619"]
  }

  owners = ["self"]
}

# Different not hardcoded image for spots.
# There is option that env will be rotated when new image will be created
# but spot will install latest epoch version there.
data "aws_ami" "ami_spot" {
  most_recent = true

  filter {
    name   = "name"
    values = ["epoch-ubuntu-16.04-*"]
  }

  owners = ["self"]
}

resource "aws_instance" "static_node" {
  count                = "${var.static_nodes}"
  ami                  = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.epoch.name}"

  tags {
    Name  = "ae-${var.env}-static-node"
    env   = "${var.env}"
    role  = "epoch"
    color = "${var.color}"
  }

  user_data = "${data.template_file.user_data.rendered}"

  subnet_id              = "${element( var.subnets, 1)}"
  vpc_security_group_ids = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]
}

resource "aws_launch_configuration" "spot" {
  name_prefix          = "ae-${var.env}-spot-nodes_"
  iam_instance_profile = "${aws_iam_instance_profile.epoch.name}"
  image_id             = "${data.aws_ami.ami_spot.id}"
  instance_type        = "${var.instance_type}"
  spot_price           = "${var.spot_price}"
  security_groups      = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${data.template_file.user_data.rendered}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.bash")}"

  vars = {
    region            = "${data.aws_region.current.name}"
    color             = "${var.color}"
    env               = "${var.env}"
    epoch_version     = "${var.epoch["version"]}"
    epoch_beneficiary = "${var.epoch["beneficiary"]}"
  }
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
