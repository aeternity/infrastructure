resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.env}"
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(split(",", lookup(var.availability_zones, data.aws_region.current.name)))}"
  availability_zone       = "${element(split(",",lookup(var.availability_zones, data.aws_region.current.name)), count.index)}"
  cidr_block              = "10.0.${count.index+length(data.aws_availability_zones.available.names)}.0/24"                     #small hack to be able to recreate subnets without conflict.
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${element(split(",",lookup(var.availability_zones, data.aws_region.current.name)), count.index)}"
  }
}

output "subnets" {
  value = "${aws_subnet.subnet.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_route_table_association" "rta" {
  count          = "${length(split(",", lookup(var.availability_zones, data.aws_region.current.name)))}"
  subnet_id      = "${aws_subnet.subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.rt.id}"
}
