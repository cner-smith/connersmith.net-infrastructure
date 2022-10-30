terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">=0.14.9" 

    backend "s3" {
      bucket = "connersmith-terraform"
      key    = "dev/terraform.tfstate"
      region = "us-east-1"
    }
}

provider "aws" {
  version = "~>3.0"
  region = "us-east-1"
}

provider "aws" {
  alias  = "acm_provider"
  version = "~>3.0"
  region = "us-east-1"
}
