# =============================================================================
# resume.connersmith.net  →  302 redirect to your Google Doc resume
# =============================================================================
# Adds a `resume` subdomain backed by CloudFront + a CloudFront Function that
# 302-redirects every request to the live Google Doc. The Doc URL stays
# auto-current; updating the URL later is a one-line change + `terraform apply`.
#
# Drop this file in your connersmith.net-infrastructure repo alongside
# cloudfront.tf / r53.tf. Reuses your existing aws_acm_certificate.default
# (the wildcard *.connersmith.net SAN already covers resume.connersmith.net),
# the existing aws.acm provider alias, and aws_route53_zone_id from variables.
#
# After `terraform apply`, the resume short-link is: https://resume.connersmith.net
# =============================================================================

variable "resume_redirect_url" {
  description = "Live Google Doc resume URL. Update + apply to change where the short-link points."
  type        = string
  default     = "https://docs.google.com/document/d/1-b1ePqh4f0aRT6qrMntG_Ph601Z-YGMIYqeDR_Kxklo/edit"
}

# CloudFront Function — runs at the viewer edge, returns a 302 to the Google Doc.
# 302 (not 301) so browsers don't permanently cache the target — lets you swap
# the URL later without users seeing a stale cached redirect.
resource "aws_cloudfront_function" "resume_redirect" {
  name    = "resume-redirect"
  runtime = "cloudfront-js-1.0"
  comment = "302 redirect resume.connersmith.net -> Google Doc"
  publish = true
  code    = <<-EOT
    function handler(event) {
      return {
        statusCode: 302,
        statusDescription: 'Found',
        headers: {
          'location':      { value: '${var.resume_redirect_url}' },
          'cache-control': { value: 'no-cache, no-store, must-revalidate' }
        }
      };
    }
  EOT
}

# CloudFront distribution dedicated to the resume subdomain.
# The origin is never actually contacted — the viewer-request function
# short-circuits with a 302 — but CloudFront still requires one configured.
# We point at your existing root S3 bucket as a harmless dummy.
resource "aws_cloudfront_distribution" "resume" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "resume.connersmith.net - 302 to Google Doc"
  aliases         = ["resume.${var.domain_name}"]

  origin {
    domain_name = aws_s3_bucket.root_bucket.bucket_regional_domain_name
    origin_id   = "dummy-origin-resume"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "dummy-origin-resume"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Don't cache — we want URL changes to propagate immediately.
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.resume_redirect.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.default.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  tags = var.common_tags
}

# Route53 alias: resume.connersmith.net  ->  the resume CloudFront distribution
resource "aws_route53_record" "resume" {
  zone_id = var.aws_route53_zone_id
  name    = "resume.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.resume.domain_name
    zone_id                = aws_cloudfront_distribution.resume.hosted_zone_id
    evaluate_target_health = false
  }
}

output "resume_url" {
  description = "Public short-link for the resume."
  value       = "https://resume.${var.domain_name}"
}
