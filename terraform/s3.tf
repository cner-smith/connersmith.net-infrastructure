# Create an S3 bucket for redirecting requests from the root domain
# to the www version of the domain.
resource "aws_s3_bucket" "root_bucket" {
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

  tags = var.common_tags
}

resource "aws_s3_bucket_acl" "root_bucket_acl" {
  bucket = aws_s3_bucket.root_bucket.id
  acl    = "public-read"
}

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


# Create an S3 bucket for the website.
resource "aws_s3_bucket" "redirect_bucket" {
  bucket = var.website_bucket_name

  # Enable static website hosting and redirect all requests to the www domain.
  website {
    redirect_all_requests_to = "https://${var.domain_name}"
  }

  tags = var.common_tags
}

resource "aws_s3_bucket_acl" "redirect_bucket_acl" {
  bucket = aws_s3_bucket.redirect_bucket.id
  acl    = "public-read"
}

# Create an S3 bucket to store lambda files
resource "aws_s3_bucket" "artifact_repo" {
  bucket = "${var.domain_name}.repo"
}

resource "aws_s3_bucket_acl" "artifact_repo_acl" {
  bucket = aws_s3_bucket.artifact_repo.id
  acl    = "private"
}

resource "aws_s3_bucket_object" "lambda_file" {
  bucket     = aws_s3_bucket.artifact_repo.id
  key        = "visitor_count"
  acl        = "public-read"
  source     = "${path.module}/backend/visitor_count.zip"
}

terraform {
  backend "s3" {
    bucket = "connersmith.net-statefile"
    key    = "statefile.tfstate"
    region = "us-east-1"
  }
}



