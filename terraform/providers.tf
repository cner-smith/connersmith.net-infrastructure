terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

  backend "s3" {
    bucket = "connersmith-terraform"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}
