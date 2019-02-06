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
  iam_instance_profile = "ae-node"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_volume_size}"
  }

  tags {
    Name    = "ae-${var.env}-static-node"
    env     = "${var.env}"
    role    = "aenode"
    color   = "${var.color}"
    kind    = "seed"
    package = "${var.aeternity["package"]}"
  }

  user_data = "${data.template_file.user_data.rendered}"

  subnet_id              = "${element( var.subnets, 1)}"
  vpc_security_group_ids = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.bash")}"

  vars = {
    region            = "${data.aws_region.current.name}"
    env               = "${var.env}"
    bootstrap_version = "${var.bootstrap_version}"
    vault_addr        = "${var.vault_addr}"
    vault_role        = "${var.vault_role}"
  }
}

resource "aws_launch_configuration" "spot" {
  name_prefix          = "ae-${var.env}-spot-nodes_"
  iam_instance_profile = "ae-node"
  image_id             = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  spot_price           = "${var.spot_price}"
  security_groups      = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${data.template_file.spot_user_data.rendered}"
}

data "template_file" "spot_user_data" {
  template = "${file("${path.module}/templates/spot_user_data.bash")}"

  vars = {
    region            = "${data.aws_region.current.name}"
    env               = "${var.env}"
    bootstrap_version = "${var.bootstrap_version}"
    aeternity_package = "${var.aeternity["package"]}"
    vault_addr        = "${var.vault_addr}"
    vault_role        = "${var.vault_role}"
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
      value               = "aenode"
      propagate_at_launch = true
    },
    {
      key                 = "color"
      value               = "${var.color}"
      propagate_at_launch = true
    },
    {
      key                 = "package"
      value               = "${var.aeternity["package"]}"
      propagate_at_launch = true
    },
  ]
}

output "static_node_ips" {
  value = "${aws_eip_association.ip_associate.*.public_ip}"
}
