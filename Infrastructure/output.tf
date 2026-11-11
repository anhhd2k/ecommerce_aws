###############################################################################
# Cognito
###############################################################################

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool."
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito user pool."
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_client_id" {
  description = "ID of the Cognito user pool web client."
  value       = aws_cognito_user_pool_client.web_client.id
}

output "cognito_domain" {
  description = "Cognito hosted-UI domain prefix."
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_hosted_ui_url" {
  description = "Base URL of the Cognito hosted UI / OAuth2 endpoints."
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
}

###############################################################################
# Networking
###############################################################################

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "IDs of the private application-tier subnets."
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "IDs of the private database-tier subnets."
  value       = aws_subnet.db[*].id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group for RDS placement."
  value       = aws_db_subnet_group.main.name
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.main[*].id
}

###############################################################################
# Frontend / CloudFront
###############################################################################

output "frontend_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend."
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (use this to reach the frontend)."
  value       = aws_cloudfront_distribution.frontend.domain_name
}

###############################################################################
# DynamoDB
###############################################################################

output "products_table_name" {
  description = "Name of the DynamoDB products table."
  value       = aws_dynamodb_table.products.name
}

output "products_table_arn" {
  description = "ARN of the DynamoDB products table."
  value       = aws_dynamodb_table.products.arn
}

###############################################################################
# SSM Parameter Store (DB connection)
###############################################################################

output "db_parameter_names" {
  description = "Names of the DB connection parameters in SSM Parameter Store."
  value       = { for k, p in aws_ssm_parameter.db : k => p.name }
}

output "db_parameter_prefix" {
  description = "SSM path prefix for the DB connection parameters."
  value       = local.db_param_prefix
}

output "carts_table_name" {
  description = "Name of the DynamoDB products table."
  value       = aws_dynamodb_table.carts.name
}

###############################################################################
# Application Load Balancer (internal)
###############################################################################

output "alb_arn" {
  description = "ARN of the internal Application Load Balancer."
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the internal ALB (used by service URLs)."
  value       = aws_lb.main.dns_name
}

output "alb_target_group_arns" {
  description = "Map of service name to target group ARN."
  value       = { for k, tg in aws_lb_target_group.services : k => tg.arn }
}

output "service_url_parameter_names" {
  description = "Map of service name to its SSM service-url parameter name."
  value       = { for k, p in aws_ssm_parameter.service_url : k => p.name }
}

###############################################################################
# ECR
###############################################################################

output "ecr_repository_urls" {
  description = "Map of service name to ECR repository URL (for docker push)."
  value       = { for k, r in aws_ecr_repository.services : k => r.repository_url }
}

output "ecr_repository_arns" {
  description = "Map of service name to ECR repository ARN."
  value       = { for k, r in aws_ecr_repository.services : k => r.arn }
}

output "carts_table_arn" {
  description = "ARN of the DynamoDB products table."
  value       = aws_dynamodb_table.products.arn
}
