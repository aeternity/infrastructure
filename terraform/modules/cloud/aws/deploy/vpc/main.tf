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

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }
}

resource "aws_route_table_association" "rta" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.rt.id}"
}
