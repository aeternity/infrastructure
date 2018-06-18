provider "aws" {

}
data "aws_region" "current" {}


resource "aws_instance" "static_node" {
    count = "${var.static}"
    ami = "${var.ami_id}"
    instance_type = "${var.instance_type}"
    tags {
        Name = "ae-${var.env}-nodes"
    }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.static_node.id}"
}

resource "aws_launch_configuration" "spot" {
    image_id = "${var.ami_id}"
    instance_type = "${var.instance_type}"
    spot_price    = "${var.spot_price}"
}

resource "aws_autoscaling_group" "spot_fleet" {
    min_size = 1
    max_size = "${var.spot}"
    launch_configuration = "${aws_launch_configuration.spot.id}"
    vpc_zone_identifier = "${var.subnets}"
    suspended_processes = ["Termination"]
    tags = [
        {
            key                 = "Name"
            value               = "ae-${var.env}"
            propagate_at_launch = true
        }
    ]
}
