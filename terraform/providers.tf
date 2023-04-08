# Configure the AWS provider.
provider "aws" {
  region = var.aws_region

  #assume_role {
    # The role ARN within Account B to AssumeRole into. Created in step 1.
    #role_arn    = "arn:aws:iam::760268051681:role/github-actions-role"
    # (Optional) The external ID created in step 1c.
    #external_id = "githubactions"
  #}
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}