resource "aws_security_group" "ae-nodes" {
  name = "ae-${var.env}-nodes-terraform" #postfix with terraform to avoid issues with current setup

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "ae-${var.env}-nodes-terraform"
  }
}

resource "aws_security_group" "ae-gateway-nodes-loadbalancer" {
  count = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name  = "ae-${var.env}-gateway-nodes-loadbalancer"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "ae-${var.env}-gateway-nodes-loadbalancer"
  }
}

resource "aws_security_group_rule" "allow_all_internal" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "TCP"

  security_group_id        = "${aws_security_group.ae-nodes.id}"
  source_security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group_rule" "external_api_port" {
  type              = "ingress"
  from_port         = 3013
  to_port           = 3015
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group_rule" "external_healthz_port" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group_rule" "external_api_port_lb" {
  count                    = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type                     = "ingress"
  from_port                = 3013
  to_port                  = 3013
  protocol                 = "TCP"
  security_group_id        = "${aws_security_group.ae-nodes.id}"
  source_security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}

resource "aws_security_group_rule" "sync_protocol_port" {
  type              = "ingress"
  from_port         = 3015
  to_port           = 3015
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group_rule" "ssl_protocol_port" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}

resource "aws_security_group_rule" "allow_outgoing-node" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes.id}"
}

resource "aws_security_group_rule" "allow_outgoing-node-lb" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}

resource "aws_security_group" "ae-nodes-management" {
  name = "ae-${var.env}-management-terraform"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "ae-${var.env}-management-terraform"
  }
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_icmp" {
  type              = "ingress"
  from_port         = 8
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_outgoing-management" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes-management.id}"
}

resource "aws_security_group_rule" "allow_outgoing-ntp" {
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-nodes-management.id}"
}
