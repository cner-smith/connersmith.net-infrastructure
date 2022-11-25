resource "aws_route53_zone" "this" {
  name = "connersmith.net"
}

resource "aws_route53_record" "main" {
  for_each = {
    for dvo in aws_acm_certificate.connersmith_acm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id
}