# The aws_iam_role resource creates an IAM role named iam_for_lambda
# that allows the lambda.amazonaws.com service to assume it.
# This role is used as the execution role for the Lambda function.
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

# The aws_iam_policy resource creates an IAM policy that allows
# the Lambda function to interact with the aws_dynamodb_table resource named visitor_count.
# This policy is attached to the aws_iam_role created earlier.
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
        "Sid" : "SpecificTable",
        "Action" : [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Get*",
          "dynamodb:Put*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:Update*"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.visitor_count.name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

# The data "archive_file" block creates a zip archive of the Python code located in the backend folder of the module.
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/backend/"
  output_path = "${path.module}/backend/visitor_count.zip"
}

# The aws_lambda_function resource creates the Lambda function with the name lambda_visitor_count
# and sets its configuration, such as its handler, runtime, and execution role.
# It also sets an environment variable DYNAMOTABLE to the name of the DynamoDB table created elsewhere in the Terraform code.
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

# the aws_lambda_permission resource sets up permissions for API Gateway to invoke the Lambda function.
# It allows apigateway.amazonaws.com to invoke the aws_lambda_function resource and is triggered by a certain source_arn.
resource "aws_lambda_permission" "visitor_count_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "lambda_visitor_count"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_count_api.execution_arn}/*"
}