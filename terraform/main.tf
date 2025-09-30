provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "auth" {
  function_name    = "lambda-auth"
  handler          = "src/index.handler"
  runtime          = "nodejs20.x"
  role             = "arn:aws:iam::065939301012:role/lambda-auth-role"
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
}

resource "aws_api_gateway_rest_api" "API" {
  name = "lambda-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "Resource" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_rest_api.API.root_resource_id
  path_part   = "customer-auth"
}

resource "aws_api_gateway_method" "Method" {
  rest_api_id   = aws_api_gateway_rest_api.API.id
  resource_id   = aws_api_gateway_resource.Resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "Integration" {
  rest_api_id             = aws_api_gateway_rest_api.API.id
  resource_id             = aws_api_gateway_resource.Resource.id
  http_method             = aws_api_gateway_method.Method.http_method
  integration_http_method = "POST"              # 👈 sempre POST para Lambda
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

resource "aws_lambda_permission" "apigw-lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.API.execution_arn}/*/${aws_api_gateway_method.Method.http_method}${aws_api_gateway_resource.Resource.path}"
}

resource "aws_api_gateway_deployment" "example" {
  depends_on  = [aws_api_gateway_integration.Integration]
  rest_api_id = aws_api_gateway_rest_api.API.id
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.API.id
  stage_name    = "dev"
}