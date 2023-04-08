# Create an API Gateway endpoint
resource "aws_api_gateway_rest_api" "visitor_count_api" {
  name = "visitor_count_api"
}

resource "aws_api_gateway_resource" "visitor_count_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  path_part   = "visitor_count"
}

resource "aws_api_gateway_method" "visitor_count_get" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor_count_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.visitor_count_get.http_method
  status_code = "200"
   response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = "'https://${var.domain_name}'",
      "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
      "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    }
  response_models = {
    "application/json" = aws_api_gateway_model.visitor_count_model.name
  }
  depends_on = [aws_api_gateway_method.visitor_count_get]
}

resource "aws_api_gateway_integration" "visitor_count_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id             = aws_api_gateway_resource.visitor_count_resource.id
  http_method             = aws_api_gateway_method.visitor_count_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  credentials = aws_iam_role.api_gateway_execution_role.arn
  uri                     = aws_lambda_function.lambda_visitor_count.invoke_arn
  depends_on              = [aws_api_gateway_method.visitor_count_get, aws_lambda_function.lambda_visitor_count]
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_visitor_count.invoke_arn
}

resource "aws_api_gateway_deployment" "visitor_count_deployment" {
  depends_on = [
    aws_api_gateway_integration.visitor_count_integration,
    aws_api_gateway_integration.lambda_root,
  ]
  stage_name  = "Dev"
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name     = "api.connersmith.net"
  certificate_arn = aws_acm_certificate_validation.default.certificate_arn


  depends_on = [aws_acm_certificate_validation.default]
}

resource "aws_api_gateway_base_path_mapping" "hit" {
  api_id      = aws_api_gateway_rest_api.visitor_count_api.id
  stage_name  = aws_api_gateway_deployment.visitor_count_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path   = "Prod"
}

resource "aws_api_gateway_model" "visitor_count_model" {
  rest_api_id  = aws_api_gateway_rest_api.visitor_count_api.id
  name         = "visitorcountmodel"
  content_type = "application/json"
  schema = jsonencode({
    "$schema" : "http://json-schema.org/draft-04/schema#",
    "title" : "VisitorCountSchema",
    "type" : "object",
    "properties" : {
      "hits" : {
        "type" : "integer"
      }
    }
  })
}

resource "aws_api_gateway_integration_response" "visitor_count_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.visitor_count_get.http_method
  status_code = "200"
  response_templates = {
    "application/json" = jsonencode({ hits = "$context.authorizer.claims.hits" })
  }
  depends_on = [
    aws_api_gateway_method.visitor_count_get,
    aws_api_gateway_integration.lambda_root,
  ]
}

resource "aws_iam_role" "api_gateway_execution_role" {
  name = "api_gateway_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  # Allow API Gateway to invoke Lambda functions
  # Replace <lambda-arn> with the ARN of your Lambda function
  # Replace <region> with the region your Lambda function is deployed in
  # Replace <account-id> with your AWS account ID
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "lambda:InvokeFunction"
        Effect = "Allow"
        Resource = "arn:aws:lambda:${var.aws_region}:760268051681:function:${aws_lambda_function.lambda_visitor_count.name}"
      }
    ]
  })
}


# Get the API gateway endpoint url
output "api_gateway_endpoint" {
  value = "${aws_api_gateway_deployment.visitor_count_deployment.invoke_url}/visitor_count_deployment"
}