resource "aws_route53_health_check" "health" {
  count             = "${length(var.loadbalancers)}"
  fqdn              = "${element(var.loadbalancers, count.index)}"
  port              = 3013
  type              = "HTTP"
  resource_path     = "/v2/blocks/top"
  measure_latency   = false
  failure_threshold = "4"
  request_interval  = 30
}

resource "aws_route53_record" "api-eu-west-2" {
  count   = "${length(var.loadbalancers)}"
  zone_id = "${var.dns_zone}"
  name    = "${var.api_dns}"
  type    = "A"

  health_check_id = "${element( aws_route53_health_check.health.*.id, count.index)}"
  set_identifier  = "eu-west-2"

  alias {
    name                   = "${element(var.loadbalancers, count.index)}"
    zone_id                = "${element(var.loadbalancers_zones, count.index)}"
    evaluate_target_health = true
  }

  latency_routing_policy = {
    region = "eu-west-2"
  }
}
