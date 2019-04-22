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
    Name              = "ae-${var.env}-static-node"
    env               = "${var.env}"
    envid             = "${var.envid}"
    role              = "aenode"
    color             = "${var.color}"
    kind              = "seed"
    package           = "${var.aeternity["package"]}"
    bootstrap_version = "${var.bootstrap_version}"
    vault_addr        = "${var.vault_addr}"
    vault_role        = "${var.vault_role}"
  }

  user_data = "${data.template_file.user_data.rendered}"

  subnet_id              = "${element( var.subnets, 1)}"
  vpc_security_group_ids = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ebs_volume" "ebs" {
  count             = "${var.additional_storage > 0 ? var.static_nodes : 0}"
  availability_zone = "${element(aws_instance.static_node.*.availability_zone, count.index)}"
  size              = "${var.additional_storage_size}"

  tags {
    Name              = "ae-${var.env}-static-node"
    env               = "${var.env}"
    role              = "aenode"
    color             = "${var.color}"
    kind              = "seed"
    package           = "${var.aeternity["package"]}"
    bootstrap_version = "${var.bootstrap_version}"
    vault_addr        = "${var.vault_addr}"
    vault_role        = "${var.vault_role}"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count       = "${var.additional_storage > 0 ? var.static_nodes : 0}"
  device_name = "/dev/sdh"
  volume_id   = "${element(aws_ebs_volume.ebs.*.id, count.index)}"
  instance_id = "${element(aws_instance.static_node.*.id, count.index)}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/${var.user_data_file}")}"

  vars = {
    region            = "${data.aws_region.current.name}"
    env               = "${var.env}"
    bootstrap_version = "${var.bootstrap_version}"
    vault_addr        = "${var.vault_addr}"
    vault_role        = "${var.vault_role}"
  }
}

resource "aws_launch_configuration" "spot" {
  count                = "${var.spot_nodes > 0 ? 1 : 0}"
  name_prefix          = "ae-${var.env}-spot-nodes-"
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

resource "aws_launch_configuration" "spot-with-additional-storage" {
  count                = "${var.spot_nodes > 0 ? 1 : 0}"
  name_prefix          = "ae-${var.env}-spot-nodes-"
  iam_instance_profile = "ae-node"
  image_id             = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  spot_price           = "${var.spot_price}"
  security_groups      = ["${aws_security_group.ae-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_volume_size}"
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = "${var.additional_storage_size}"
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${data.template_file.spot_user_data.rendered}"
}

data "template_file" "spot_user_data" {
  template = "${file("${path.module}/templates/${var.spot_user_data_file}")}"

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
  count                = "${ var.spot_nodes > 0 ? 1 : 0 }"
  name                 = "${var.additional_storage > 0 ? aws_launch_configuration.spot-with-additional-storage.name : aws_launch_configuration.spot.name}"
  min_size             = "${var.spot_nodes}"
  max_size             = "${var.spot_nodes}"
  launch_configuration = "${var.additional_storage > 0 ? aws_launch_configuration.spot-with-additional-storage.name : aws_launch_configuration.spot.name}"
  vpc_zone_identifier  = ["${var.subnets}"]

  #  suspended_processes  = ["Terminate"]
  termination_policies = ["OldestInstance"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "ae-${var.env}-nodes"
      propagate_at_launch = true
    },
    {
      key                 = "kind"
      value               = "peer"
      propagate_at_launch = true
    },
    {
      key                 = "env"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "envid"
      value               = "${var.envid}"
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
    {
      key                 = "bootstrap_version"
      value               = "${var.bootstrap_version}"
      propagate_at_launch = true
    },
    {
      key                 = "vault_addr"
      value               = "${var.vault_addr}"
      propagate_at_launch = true
    },
    {
      key                 = "vault_role"
      value               = "${var.vault_role}"
      propagate_at_launch = true
    },
  ]
}

output "static_node_ips" {
  value = "${aws_eip_association.ip_associate.*.public_ip}"
}
