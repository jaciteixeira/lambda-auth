provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-auth-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "auth" {
  function_name = "lambda-auth"
  handler       = "src/index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/../build/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/lambda.zip")
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "customer-auth-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_cpf" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /customer-auth"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
