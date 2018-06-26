resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
}

output "subnets" {
  value = "${aws_subnet.subnet.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
