terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.56"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}