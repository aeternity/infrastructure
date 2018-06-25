resource "aws_eip" "ip" {
  count = "${var.static_ip}"
}

resource "aws_eip_association" "ip_associate" {
  count         = "${var.static_ip}"
  instance_id   = "${aws_instance.static_node.id}"
  allocation_id = "${aws_eip.ip.id}"
}
