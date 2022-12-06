resource "aws_acm_certificate" "connersmith_acm" {
  provider                  = aws.acm_provider
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags = {
    Environment = "dev"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_acm_certificate_validation.validation]
}

resource "aws_acm_certificate_validation" "validation" {
  timeouts {
    create = "5m"
  }
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.connersmith_acm.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
  depends_on              = [aws_acm_certificate.connersmith_acm]
}