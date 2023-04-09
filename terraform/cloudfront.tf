# creates an AWS CloudFront distribution for the website,
# which will use an S3 bucket as the origin for the website content
# and an API Gateway for the backend API. The enabled parameter is set to true to enable the distribution,
# and default_root_object is set to index.html to serve as the default page.
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.root_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.root_bucket.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  origin {
    domain_name = "api.${var.domain_name}"
    origin_id   = "api.${aws_s3_bucket.root_bucket.id}"
    origin_path = "/Dev/*"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"



  # The default_cache_behavior and ordered_cache_behavior blocks define the caching behavior of the CloudFront distribution for the website and API respectively.
  # Both blocks set the allowed_methods and cached_methods parameters to allow and cache GET and HEAD requests.
  # The target_origin_id parameter is set to the ID of the corresponding origin.
  # forwarded_values block specifies whether to forward query strings or cookies to the origin.
  # viewer_protocol_policy parameter is set to "redirect-to-https" to redirect HTTP requests to HTTPS.
  # The min_ttl, default_ttl, and max_ttl parameters define the minimum, default,
  # and maximum TTL values for cached objects respectively. The compress parameter enables or disables compression of objects.
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.root_bucket.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000
    default_ttl            = 31536000
    max_ttl                = 31536000
    compress               = true
  }

  ordered_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "api.${aws_s3_bucket.root_bucket.id}"
    path_pattern     = "/api/*"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000
    default_ttl            = 31536000
    max_ttl                = 31536000
    compress               = true
  }


  # The aliases parameter specifies the domain names to associate with the CloudFront distribution.
  aliases = ["www.${var.domain_name}", "${var.domain_name}"]

  # The custom_error_response block defines a custom error response when a 404 error occurs.
  # In this case, it will return the content of 404.html instead of the default error message.
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  # The viewer_certificate block defines the SSL certificate used by the CloudFront distribution.
  # The acm_certificate_arn parameter specifies the ARN of the ACM certificate to use.
  # ssl_support_method specifies the SSL support method to use. minimum_protocol_version parameter sets the minimum TLS protocol version to use.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.default.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # The restrictions block defines any restrictions on the CloudFront distribution.
  # In this case, there are no restrictions on geographic locations.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.common_tags
}

# The aws_acm_certificate resource creates an ACM certificate for the domain name and its subdomains.
resource "aws_acm_certificate" "default" {
  provider                  = aws.acm
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# The aws_acm_certificate_validation resource validates the ACM certificate by creating DNS records in Route 53.
resource "aws_acm_certificate_validation" "default" {
  provider                = aws.acm
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}