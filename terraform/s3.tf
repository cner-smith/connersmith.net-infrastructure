# S3 bucket for website.
resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.${var.bucket_name}"
}

#Resource to attach a bucket policy to a bucket 
resource "aws_s3_bucket_policy" "www-s3-policy" {
  bucket = aws_s3_bucket.www_bucket.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::760268051681:root"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::www.connersmith.net"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::760268051681:root"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::www.connersmith.net/*"
        }
    ]
}
EOF

# S3 bucket for redirecting non-www to www.
resource "aws_s3_bucket" "root_bucket" {
  bucket = var.bucket_name
}

#Resource to attach a bucket policy to a bucket 
resource "aws_s3_bucket_policy" "s3-policy" {
  bucket = aws_s3_bucket.root_bucket.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::760268051681:root"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::connersmith.net"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::760268051681:root"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::connersmith.net/*"
        }
    ]
}
EOF

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