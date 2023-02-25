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

resource "aws_iam_policy" "iam_policy_for_lambda" {
  depends_on = [
    aws_dynamodb_table.visitor_count
  ]

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Stmt1677346969555",
        "Action" : [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:dynamodb:us-east-1:760268051681:table/${aws_dynamodb_table.visitor_count.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/backend/"
  output_path = "${path.module}/backend/visitor_count.zip"
}

# Triggers a Lambda Function to retrieve data from the DynamoDB table
resource "aws_lambda_function" "lambda_visitor_count" {
  function_name = "lambda_visitor_count"

  s3_bucket  = aws_s3_bucket.artifact_repo.bucket
  s3_key     = "visitor_count"
  handler    = "visitor_count.lambda_handler"
  runtime    = "python3.8"
  role       = aws_iam_role.iam_for_lambda.arn
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

  environment {
    variables = {
      DYNAMOTABLE = "${aws_dynamodb_table.visitor_count.name}"
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