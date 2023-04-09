# creates an A record that maps the domain name to the CloudFront distribution.
# It uses an alias block, which is a Route 53-specific feature that allows you
# to create a DNS record that points to a CloudFront distribution or an ELB load balancer.
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

# creates another A record for the API Gateway domain name, which also uses an alias block to point to the associated CloudFront distribution.
resource "aws_route53_record" "api_record" {
  zone_id = var.aws_route53_zone_id
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api.cloudfront_zone_id
    evaluate_target_health = false
  }
}

# creates a CNAME record for the www subdomain that points to the apex domain (i.e., the domain name).
# This is a common configuration that allows users to access the website using both example.com and www.example.com.
resource "aws_route53_record" "main-c-name" {
  zone_id = var.aws_route53_zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.domain_name}"]
}

# creates Route 53 validation records for the ACM certificate. This block uses for_each to create multiple DNS records based on the
# domain_validation_options list in the ACM certificate. The for_each block creates a map with the domain name as the key and the DNS record
# attributes as the value. Then it uses the name, records, ttl, type, and zone_id arguments to create the DNS record.
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = var.aws_route53_zone_id
}