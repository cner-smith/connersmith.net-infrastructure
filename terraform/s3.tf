# Create an S3 bucket for the website.
resource "aws_s3_bucket" "website" {
  bucket = var.website_bucket_name
  acl    = "public-read"

  # Enable static website hosting on the bucket.
  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = var.common_tags
}


# Create an S3 bucket for redirecting requests from the root domain
# to the www version of the domain.
resource "aws_s3_bucket" "redirect" {
  bucket = var.root_domain_bucket_name

  # Set the policy to allow redirects from the bucket.
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow Public Access to All Objects",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.root_domain_bucket_name}/*"
    }
  ]
}
EOF

  # Enable static website hosting and redirect all requests to the www domain.
  website {
    redirect_all_requests_to = "https://www.${var.domain_name}"
  }

  tags = var.common_tags
}

# Create a CloudFront distribution for the website.
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website.id}"

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

  # Use the default CloudFront cache behavior.
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

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

  # Set the CloudFront distribution to use the www version of the domain.
  aliases = ["www.${var.domain_name}"]

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  # Use the default CloudFront SSL certificate.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.primary.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.common_tags
}

# Create a Route53 hosted zone for the domain.
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

# Create an ACM certificate for the domain.
resource "aws_acm_certificate" "primary" {
  provider                  = aws.acm_provider
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a DNS record for the domain that points to the CloudFront distribution.
resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
