# Create an S3 bucket for redirecting requests from the root domain
# to the www version of the domain.
resource "aws_s3_bucket" "root_bucket" {
  bucket = var.root_domain_bucket_name
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["Etag"]
    max_age_seconds = 3000
  }

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


# Create an S3 bucket for the website.
resource "aws_s3_bucket" "redirect_bucket" {
  bucket = var.website_bucket_name
  acl    = "public-read"
  
  # Enable static website hosting and redirect all requests to the www domain.
  website {
    redirect_all_requests_to = "https://${var.domain_name}"
  }

  tags = var.common_tags
}

# Create an S3 bucket to store lambda files
resource "aws_s3_bucket" "artifact_repo" {
  bucket = "${var.domain_name}.repo"
  acl    = "private"
}


terraform {
  backend "s3" {
    bucket = "connersmith.net-statefile"
    key    = "statefile.tfstate"
    region = "us-east-1"
  }
}



