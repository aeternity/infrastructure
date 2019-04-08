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

resource "aws_security_group_rule" "allow_outgoing-node-gateway" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes.id}"
}

resource "aws_security_group_rule" "http_protocol_port" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}

resource "aws_security_group_rule" "healthz_protocol_port" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}

resource "aws_security_group" "ae-gateway-nodes" {
  count = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name  = "ae-${var.env}-gateway-nodes"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "ae-${var.env}-gateway-nodes"
  }
}

resource "aws_security_group_rule" "allow_outgoing-node-lb" {
  count = "${var.gateway_nodes_min > 0 ? 1 : 0}"

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}

resource "aws_security_group_rule" "allow_all_internal_gateway_nodes" {
  count     = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "TCP"

  security_group_id        = "${aws_security_group.ae-gateway-nodes.id}"
  source_security_group_id = "${aws_security_group.ae-gateway-nodes.id}"
}

resource "aws_security_group_rule" "external_gateway_healthz_port" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes.id}"
}

resource "aws_security_group_rule" "external_sync_port" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 3015
  to_port           = 3015
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ae-gateway-nodes.id}"
}

resource "aws_security_group_rule" "external_api_port_lb" {
  count                    = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  type                     = "ingress"
  from_port                = 3013
  to_port                  = 3013
  protocol                 = "TCP"
  security_group_id        = "${aws_security_group.ae-gateway-nodes.id}"
  source_security_group_id = "${aws_security_group.ae-gateway-nodes-loadbalancer.id}"
}
