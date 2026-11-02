resource "aws_cognito_user_pool" "ecommerce" {
  name = "ecommerce-app"

  username_attributes = ["email"]

  auto_verified_attributes = [ "email" ]

  schema {
    attribute_data_type = "String"
    name = "email"
    required = true
    mutable = true
  }

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }


  tags = {
    Enviroment = "dev"
  }

}


resource "aws_cognito_user_pool_client" "client_pool" {
  name = "ecommerce-app-client"
  user_pool_id = aws_cognito_user_pool.ecommerce.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  access_token_validity = 60
  id_token_validity = 60
  refresh_token_validity = 30

  callback_urls = [ "http://nightmare.io.vn" ]
}