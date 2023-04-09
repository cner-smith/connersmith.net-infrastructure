# Configure the AWS provider.
provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}