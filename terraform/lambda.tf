# create iam role for Lambda functions
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Triggers a Lambda Function to retrieve data from the DynamoDB table
resource "aws_lambda_function" "lambda_visitor_count" {
  function_name = "lambda_visitor_Count"
  s3_bucket     = aws_s3_bucket.artifact_repo.bucket
  handler       = "index.lambda_handler"
  runtime       = "nodejs18.x"
  filename      = "${path.module}/python/lambda_visitor_count.zip"
  role          = aws_iam_role.iam_for_lambda.arn

  environment {
    variables = {
      DYNAMOTABLE = aws_dynamodb_table.visitor_count.name
    }
  }
}

resource "aws_lambda_permission" "visitor_count_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_visitor_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_count_api.arn}/*/*/*"
}