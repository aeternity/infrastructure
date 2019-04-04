resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.api_dns}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.dns_zone}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_route53_record" "main-api" {
  zone_id = "${var.dns_zone}"
  name    = "${var.api_dns}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.cf.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.cf.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_distribution" "cf" {
  enabled = true

  origin {
    domain_name = "origin-${var.api_dns}"
    origin_id   = "main"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2", "SSLv3", "TLSv1", "TLSv1.1"]
    }
  }

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = "main"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["${var.api_dns}"]

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.cert.arn}"

    ssl_support_method = "sni-only"
  }
}

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

resource "aws_route53_record" "origin-api" {
  count   = "${length(var.loadbalancers_regions)}"
  zone_id = "${var.dns_zone}"
  name    = "origin-${var.api_dns}"
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
