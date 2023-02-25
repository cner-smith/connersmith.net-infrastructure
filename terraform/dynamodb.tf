# Create a DynamoDB table to store the visitor count
resource "aws_dynamodb_table" "visitor_count" {
  name           = var.aws_dynamodb_table_name
  hash_key       = "site_id"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "site_id"
    type = "S"
  }
}