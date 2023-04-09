# creates an S3 bucket to redirect requests from the root domain to the www version of the domain.
# The bucket name is taken from the root_domain_bucket_name variable, and the tags are set to the common_tags variable.
resource "aws_s3_bucket" "root_bucket" {
  bucket = var.root_domain_bucket_name
  tags   = var.common_tags
}

# configures the website hosting for the root domain bucket.
# The index_document block specifies that the index.html file should be served as the index document,
# and the error_document block specifies that the 404.html file should be used as the error document.
resource "aws_s3_bucket_website_configuration" "root_bucket_config" {
  bucket = aws_s3_bucket.root_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# creates a policy that allows public access to all objects in the root domain bucket.
# The policy JSON is created using the jsonencode function, which converts a Terraform data structure to a JSON string.
resource "aws_s3_bucket_policy" "root_bucket_policy" {
  bucket = aws_s3_bucket.root_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Allow Public Access to All Objects",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${var.root_domain_bucket_name}/*"
      }
    ]
  })
}

# sets the ACL for the root domain bucket to public-read, which makes all objects in the bucket publicly readable.
resource "aws_s3_bucket_acl" "root_bucket_acl" {
  bucket = aws_s3_bucket.root_bucket.id
  acl    = "public-read"
}

# configures CORS for the root domain bucket. The cors_rule blocks define two rules: one that allows PUT and POST requests with any headers and origin,
# and one that allows GET requests with any origin. The max_age_seconds parameter specifies how long the CORS policy should be cached by clients.
resource "aws_s3_bucket_cors_configuration" "root_bucket" {
  bucket = aws_s3_bucket.root_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["Etag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}


# creates an S3 bucket for the website. The bucket name is taken from the website_bucket_name variable, and the tags are set to the common_tags variable.
resource "aws_s3_bucket" "redirect_bucket" {
  bucket = var.website_bucket_name

  tags = var.common_tags
}

# configures the website hosting for the website bucket.
# The redirect_all_requests_to block redirects all requests to the www version of the domain.
resource "aws_s3_bucket_website_configuration" "redirect_bucket_config" {
  bucket = aws_s3_bucket.redirect_bucket.id

  # Enable static website hosting and redirect all requests to the www domain.
  redirect_all_requests_to {
    host_name = "https://www.${var.domain_name}"
  }
}

# sets the ACL for the website bucket to public-read, which makes all objects in the bucket publicly readable.
resource "aws_s3_bucket_acl" "redirect_bucket_acl" {
  bucket = aws_s3_bucket.redirect_bucket.id
  acl    = "public-read"
}

# creates an S3 bucket to store Lambda files. The bucket name is ${var.domain_name}.repo.
resource "aws_s3_bucket" "artifact_repo" {
  bucket = "${var.domain_name}.repo"
}

# sets the ACL for the artifact repository bucket to private, which makes all objects in the bucket only accessible by authorized users.
resource "aws_s3_bucket_acl" "artifact_repo_acl" {
  bucket = aws_s3_bucket.artifact_repo.id
  acl    = "private"
}

# uploads the visitor_count.zip file to the artifact repository bucket.
# The object key is set to visitor_count, and the ACL is set to public-read, which makes the object publicly readable.
resource "aws_s3_object" "lambda_file" {
  bucket = aws_s3_bucket.artifact_repo.id
  key    = "visitor_count"
  acl    = "public-read"
  source = "${path.module}/backend/visitor_count.zip"
}

# configures the backend to store the state file in an S3 bucket. The bucket, key, and region parameters are set to the values for the state file.
terraform {
  backend "s3" {
    bucket = "connersmith.net-statefile"
    key    = "statefile.tfstate"
    region = "us-east-1"
  }
}



