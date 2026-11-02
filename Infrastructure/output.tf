output "cognito_client_id" {
  value = aws_cognito_user_pool_client.web_client.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}