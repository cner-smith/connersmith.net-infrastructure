# Create an API Gateway endpoint
# creates a REST API in AWS API Gateway, which will serve as the endpoint for your application.
resource "aws_api_gateway_rest_api" "visitor_count_api" {
  name = "visitor_count_api"
}

# creates a resource in the API Gateway REST API, which represents a part of the URL path.
# In this case, the resource is called "visitor_count" and it is a child of the root resource.
resource "aws_api_gateway_resource" "visitor_count_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  path_part   = "visitor_count"
}

#creates a method in the API Gateway REST API, which is associated with the "visitor_count"
# resource and responds to HTTP GET requests. The "authorization" field specifies that no authentication is required to access this method.
resource "aws_api_gateway_method" "visitor_count_get" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor_count_resource.id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.visitor_count_resource]
}

# creates a method response for a GET request on the API Gateway. 
# It sets headers to allow Cross-Origin Resource Sharing (CORS) from all domains by using the wildcard "*", as shown in the configuration. 
resource "aws_api_gateway_method_response" "cors_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.visitor_count_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Credentials" = false
  }
  response_models = {
    "application/json" = aws_api_gateway_model.visitor_count_model.name
  }
  depends_on = [aws_api_gateway_method.visitor_count_get]
}

# creates an integration for a GET request on the API Gateway. 
# It forwards requests to a Lambda function, using the GET method with AWS_PROXY integration type.
resource "aws_api_gateway_integration" "visitor_count_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id             = aws_api_gateway_resource.visitor_count_resource.id
  http_method             = aws_api_gateway_method.visitor_count_get.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  credentials             = aws_iam_role.api_gateway_execution_role.arn
  uri                     = aws_lambda_function.lambda_visitor_count.invoke_arn
  depends_on              = [aws_api_gateway_method.visitor_count_get, aws_lambda_function.lambda_visitor_count]
}

# creates a method for a GET request on the root resource of the API Gateway. 
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.visitor_count_resource]
}

# creates an integration for a GET request on the root resource of the API Gateway. 
# It forwards requests to a Lambda function, using the GET method with AWS_PROXY integration type.
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.proxy_root.http_method

  credentials = aws_iam_role.api_gateway_execution_role.arn

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_visitor_count.invoke_arn
}

# creates an API Gateway method resource to handle HTTP OPTIONS requests.
# It specifies that the method should have authorization = "NONE", and should be associated with a specific REST API and resource.
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor_count_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.visitor_count_resource]
}

#  creates an API Gateway integration resource for the OPTIONS method. It specifies that the integration should be a MOCK integration,
# meaning that it does not actually send requests to a backend service. Instead, it returns a fixed response that indicates which headers and methods are allowed.
resource "aws_api_gateway_integration" "options" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id             = aws_api_gateway_resource.visitor_count_resource.id
  http_method             = aws_api_gateway_method.options.http_method
  integration_http_method = aws_api_gateway_method.options.http_method
  type                    = "MOCK"
  depends_on = [aws_api_gateway_method.options]
}

# creates a method response for the OPTIONS method. It specifies that the response should have a 200 status code,
# and should include headers that indicate which headers and methods are allowed.
resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.cors_method_response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.options]
}

# creates an integration response for the OPTIONS method. It specifies that the response should have a 200 status code,
# and should include headers that indicate which headers and methods are allowed.
# It also specifies a response template for the "application/json" content type,
# but in this case the template is empty since this is a MOCK integration and the response is not generated dynamically.
resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.cors_method_response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.options]
}

# This resource creates a deployment for the API Gateway, which specifies the stage name and the REST API ID.
# The depends_on attribute lists the resources that this deployment depends on, including the API Gateway integration and the Lambda root.
resource "aws_api_gateway_deployment" "visitor_count_deployment" {
  depends_on = [
    aws_api_gateway_integration.visitor_count_integration,
    aws_api_gateway_integration.lambda_root,
  ]
  stage_name  = "Dev"
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
}

# This resource creates a domain name for the API Gateway, with a specified domain name and a certificate ARN.
# The depends_on attribute lists the resource that this domain name depends on, which is the ACM certificate validation.
resource "aws_api_gateway_domain_name" "api" {
  domain_name     = "api.${var.domain_name}"
  certificate_arn = aws_acm_certificate_validation.default.certificate_arn


  depends_on = [aws_acm_certificate_validation.default]
}

# This resource creates a base path mapping for the API Gateway, which maps the base path to a specific stage of the API Gateway deployment.
# The api_id attribute specifies the REST API ID, the stage_name attribute specifies the stage name of the deployment,
# and the domain_name attribute specifies the domain name of the API Gateway.
#  This resource ensures that requests to the root path of the domain name are directed to the specified stage of the API Gateway deployment.
resource "aws_api_gateway_base_path_mapping" "hit" {
  api_id      = aws_api_gateway_rest_api.visitor_count_api.id
  stage_name  = aws_api_gateway_deployment.visitor_count_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path   = "Prod"
}

# This resource creates a model for the API Gateway, which specifies the schema for the request or response.
# The rest_api_id attribute specifies the REST API ID, the name attribute specifies the name of the model,
# the content_type attribute specifies the content type of the schema, and the schema attribute specifies the JSON schema for the model.
# The visitor_count_model resource specifies a schema for the visitor count data, and the empty resource specifies an empty schema for certain responses.
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

# resource defines a response for the API Gateway integration.
# In this case, it maps the hits attribute from the Lambda function response to the hits property
# in the response body of the API Gateway method. It also sets the CORS headers to allow requests from the domain specified in the ${var.domain_name} variable.
resource "aws_api_gateway_integration_response" "visitor_count_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.visitor_count_get.http_method
  status_code = aws_api_gateway_method_response.cors_method_response_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain_name}'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
  }
  response_templates = {
    "application/json" = jsonencode({ hits = "$context.authorizer.claims.hits" })
  }
  depends_on = [
    aws_api_gateway_method.visitor_count_get,
    aws_api_gateway_integration.visitor_count_integration,
  ]
}

# resource creates an IAM role that can be assumed by the API Gateway service.
# The assume_role_policy attribute specifies that only the API Gateway service is allowed to assume this role.
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
}

#resource creates an IAM policy that allows the API Gateway service to invoke the Lambda function.
# The policy attribute specifies the resource ARN of the Lambda function that is allowed to be invoked.
resource "aws_iam_policy" "iam_policy_for_gateway" {
  depends_on = [
    aws_dynamodb_table.visitor_count
  ]

  name        = "aws_iam_policy_for_terraform_aws_gateway_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws Apigateway role"
  # Allow API Gateway to invoke Lambda functions
  # Replace <lambda-arn> with the ARN of your Lambda function
  # Replace <region> with the region your Lambda function is deployed in
  # Replace <account-id> with your AWS account ID
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = "arn:aws:lambda:${var.aws_region}:760268051681:function:${aws_lambda_function.lambda_visitor_count.function_name}"
      }
    ]
  })
}

# resource attaches the IAM policy to the IAM role created earlier, which grants the API Gateway service permission to invoke the Lambda function.
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_gateway_role" {
  role       = aws_iam_role.api_gateway_execution_role.name
  policy_arn = aws_iam_policy.iam_policy_for_gateway.arn
}