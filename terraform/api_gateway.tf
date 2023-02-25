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

resource "aws_api_gateway_integration" "visitor_count_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id             = aws_api_gateway_resource.visitor_count_resource.id
  http_method             = aws_api_gateway_method.visitor_count_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_visitor_count.invoke_arn
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

  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  }

resource "aws_api_gateway_domain_name" "api" {
  certificate_arn = var.acm_id
  domain_name     = "api.${var.domain_name}"
}

resource "aws_api_gateway_base_path_mapping" "hit" {
  api_id      = aws_api_gateway_rest_api.visitor_count_api.id
  stage_name  = aws_api_gateway_deployment.visitor_count_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path = "Prod"
}

# Get the API gateway endpoint url
output "api_gateway_endpoint" {
  value = "${aws_api_gateway_deployment.visitor_count_deployment.invoke_url}/visitor_count_deployment"
}