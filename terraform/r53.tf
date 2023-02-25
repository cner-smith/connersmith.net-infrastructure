# Create a DNS record for the domain that points to the CloudFront distribution.
resource "aws_route53_record" "website" {
  zone_id = var.aws_route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "main-c-name" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.domain_name}"]
}

output "r53_ns" {
  value = aws_route53_zone.hosted_zone.name_servers
}