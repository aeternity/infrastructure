resource "aws_route53_health_check" "health" {
  count             = "${length(var.loadbalancers_regions)}"
  fqdn              = "${element(var.loadbalancers, count.index)}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/v2/blocks/top"
  measure_latency   = false
  failure_threshold = "4"
  request_interval  = 30
}

resource "aws_route53_record" "api" {
  count   = "${length(var.loadbalancers_regions)}"
  zone_id = "${var.dns_zone}"
  name    = "${var.api_dns}"
  type    = "A"

  health_check_id = "${element( aws_route53_health_check.health.*.id, count.index)}"
  set_identifier  = "${element(var.loadbalancers_regions, count.index)}"

  alias {
    name                   = "${element(var.loadbalancers, count.index)}"
    zone_id                = "${element(var.loadbalancers_zones, count.index)}"
    evaluate_target_health = true
  }

  latency_routing_policy = {
    region = "${element(var.loadbalancers_regions, count.index)}"
  }
}
