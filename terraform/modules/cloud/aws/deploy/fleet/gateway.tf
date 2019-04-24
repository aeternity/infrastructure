resource "aws_lb" "gateway" {
  count              = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name               = "ae-${replace(var.env,"_","-")}-gateway"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ae-gateway-nodes-loadbalancer.id}"]
  subnets            = ["${var.subnets}"]

  enable_deletion_protection = false
}

output "gateway_lb_dns" {
  value = "${element(concat(aws_lb.gateway.*.dns_name, list("")), 0)}"
}

output "gateway_lb_zone_id" {
  value = "${element(concat(aws_lb.gateway.*.zone_id, list("")), 0)}"
}

resource "aws_alb_listener" "gateway" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  load_balancer_arn = "${aws_lb.gateway.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.gateway.arn}"
  }
}

resource "aws_alb_listener" "gateway-healthz" {
  count             = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  load_balancer_arn = "${aws_lb.gateway.arn}"
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.gateway-healthz.arn}"
  }
}

resource "aws_lb_target_group" "gateway" {
  count    = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name     = "ae-${replace(var.env,"_","-")}-gateway"
  port     = 3013
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/healthz"
    port                = 8080
    interval            = 30
  }
}

resource "aws_lb_target_group" "gateway-healthz" {
  count    = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name     = "ae-${replace(var.env,"_","-")}-gateway-healtz"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/healthz"
    port                = 8080
    interval            = 30
  }
}

resource "aws_launch_configuration" "gateway" {
  count                = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name_prefix          = "ae-${var.env}-gateway-nodes-"
  iam_instance_profile = "ae-node"
  image_id             = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  spot_price           = "${var.spot_price}"
  security_groups      = ["${aws_security_group.ae-gateway-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${data.template_file.spot_user_data.rendered}"
}

resource "aws_launch_configuration" "gateway-with-additional-storage" {
  count                = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name_prefix          = "ae-${var.env}-gateway-nodes-"
  iam_instance_profile = "ae-node"
  image_id             = "${data.aws_ami.ami.id}"
  instance_type        = "${var.instance_type}"
  spot_price           = "${var.spot_price}"
  security_groups      = ["${aws_security_group.ae-gateway-nodes.id}", "${aws_security_group.ae-nodes-management.id}"]

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

resource "aws_autoscaling_group" "gateway" {
  count                = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name                 = "${var.additional_storage > 0 ? aws_launch_configuration.gateway-with-additional-storage.name : aws_launch_configuration.gateway.name}"
  min_size             = "${var.gateway_nodes_min}"
  max_size             = "${var.gateway_nodes_max}"
  launch_configuration = "${var.additional_storage > 0 ? aws_launch_configuration.gateway-with-additional-storage.name : aws_launch_configuration.gateway.name}"
  vpc_zone_identifier  = ["${var.subnets}"]

  target_group_arns = ["${aws_lb_target_group.gateway.arn}", "${aws_lb_target_group.gateway-healthz.arn}"]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "ae-${var.env}-gateway-nodes"
      propagate_at_launch = true
    },
    {
      key                 = "kind"
      value               = "api"
      propagate_at_launch = true
    },
    {
      key                 = "env"
      value               = "${var.env}"
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

resource "aws_autoscaling_policy" "gateway-cpu-policy-up" {
  count                  = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name                   = "ae-${var.env}-gateway-cpu-up"
  autoscaling_group_name = "${aws_autoscaling_group.gateway.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "gateway-cpu-alarm-up" {
  count               = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  alarm_name          = "ae-${var.env}-gateway-cpu-alarm-up"
  alarm_description   = "cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.gateway.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.gateway-cpu-policy-up.arn}"]
}

resource "aws_autoscaling_policy" "gateway-cpu-policy-down" {
  count = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  name  = "ae-${var.env}-gateway-cpu-down"

  autoscaling_group_name = "${aws_autoscaling_group.gateway.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "gateway-cpu-alarm-down" {
  count               = "${var.gateway_nodes_min > 0 ? 1 : 0}"
  alarm_name          = "ae-${var.env}-gateway-cpu-alarm-down"
  alarm_description   = "cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.gateway.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.gateway-cpu-policy-down.arn}"]
}
