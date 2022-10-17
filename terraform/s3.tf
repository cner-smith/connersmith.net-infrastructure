# S3 bucket for website.
resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.${var.bucket_name}"
  policy = templatefile("templates/www-s3-policy.json", { bucket = "www.${var.bucket_name}" })

  tags = var.common_tags
}

# S3 bucket for redirecting non-www to www.
resource "aws_s3_bucket" "root_bucket" {
  bucket = var.bucket_name
  policy = templatefile("templates/s3-policy.json", { bucket = var.bucket_name })

  tags = var.common_tags
}






resource "aws_s3_bucket_website_configuration" "www_bucket_config" {
  bucket = "www.${var.bucket_name}"

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}

# S3 bucket for redirecting non-www to www.
resource "aws_s3_bucket_website_configuration" "root_bucket_config" {
  bucket = var.bucket_name
  redirect_all_requests_to {
    host_name = "www.${var.domain_name}"
    protocol  = "https"
  }

}
