provider "aws" {

}
data "aws_region" "current" {}


resource "aws_instance" "static_node" {
    count = "${var.static}"
    ami = "${lookup(var.ami_id, data.aws_region.current.name)}"
    instance_type = "${var.instance_type}"
    tags {
        Name = "ae-${var.env}-static-node"
    }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.static_node.id}"
}

resource "aws_launch_configuration" "spot" {
    name_prefix = "ae-${var.env}-spot-nodes_"
    image_id = "${lookup(var.ami_id, data.aws_region.current.name)}"
    instance_type = "${var.instance_type}"
    spot_price    = "${var.spot_price}"
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "spot_fleet" {
    name = "ae-${var.env}-spot-nodes"
    min_size = "${var.spot}"
    max_size = "${var.spot}"
    launch_configuration = "${aws_launch_configuration.spot.id}"
#    vpc_zone_identifier = "${var.subnets}"
    vpc_zone_identifier =  ["${split(",", lookup(var.subnets, data.aws_region.current.name))}"]
#    suspended_processes = ["Terminate"]
    termination_policies = ["OldestInstance"]
    tags = [
        {
            key                 = "Name"
            value               = "ae-${var.env}-nodes"
            propagate_at_launch = true
        }
    ]
}
