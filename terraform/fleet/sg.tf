resource "aws_security_group" "ae-nodes" {
    name = "ae-${var.env}-nodes"
}

resource "aws_security_group_rule" "allow_all_internal" {
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "TCP"

    security_group_id = "${aws_security_group.ae-nodes.id}"
    source_security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group_rule" "allow_outgoing-node" {
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group" "ae-nodes-management" {
    name = "ae-${var.env}-management"
}

resource "aws_security_group_rule" "allow_ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_epoch_1" {
    type = "ingress"
    from_port = 3013
    to_port = 3015
    protocol = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_epoch_2" {
    type = "ingress"
    from_port = 3015
    to_port = 3015
    protocol = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_epoch_icmp" {
    type = "ingress"
    from_port = 8
    to_port = -1
    protocol = "icmp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_outgoing-management" {
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.ae-nodes-management.id}"
}
