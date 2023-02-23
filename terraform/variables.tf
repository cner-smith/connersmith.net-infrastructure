# The AWS region where the Route53 hosted zone and ACM certificate should be created.
variable "aws_region" {
  default = "us-east-1"
}

# The name of the S3 bucket for the static website.
variable "website_bucket_name" {
  default = "www.connersmith.net"
}

# The name of the S3 bucket for redirecting requests from the root domain
# to the www version of the domain.
variable "root_domain_bucket_name" {
  default = "connersmith.net"
}

# The name of the s3 bucket that will store the state file
variable "backend_bucket_name" {
  default = "connersmith.net-statefile"
}

# The name of the domain (used in the redirect bucket policy and website configuration).
variable "domain_name" {
  default = "connersmith.net"
}

variable "aws_dynamodb_table_name" {
  default = "visitor_count"
}

# Common tags to apply to both S3 buckets.
variable "common_tags" {
  default = {
    Environment = "development"
  }
}