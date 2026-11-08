###############################################################################
# Global / project-wide
###############################################################################

variable "project" {
  description = "Project name, used for resource naming and tagging."
  type        = string
  default     = "ecommerce"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must contain only lowercase letters, numbers and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "Short name prefix for networking resources."
  type        = string
}

###############################################################################
# Networking
###############################################################################

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR block."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "AWS Availability Zones to spread subnets across."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }

  validation {
    condition     = length(var.availability_zones) == length(distinct(var.availability_zones))
    error_message = "availability_zones must not contain duplicates."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ). Hosts NAT Gateway, ALB."
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for the private application tier (one per AZ). Egress via NAT Gateway."
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for the private database tier (one per AZ). Isolated - no internet route."
  type        = list(string)
}

variable "nat_gateway_per_az" {
  description = "Create one NAT Gateway per AZ (true, HA) or a single shared NAT Gateway (false, cost optimized)."
  type        = bool
  default     = false
}

###############################################################################
# Authentication (Cognito)
###############################################################################

variable "cognito_callback_urls" {
  description = "Allowed callback URLs for the Cognito user pool client. Must use HTTPS."
  type        = list(string)

  validation {
    condition     = alltrue([for u in var.cognito_callback_urls : startswith(u, "https://")])
    error_message = "All cognito_callback_urls must use HTTPS."
  }
}

variable "cognito_access_token_validity" {
  description = "Access token validity in minutes."
  type        = number
  default     = 60
}

variable "cognito_id_token_validity" {
  description = "ID token validity in minutes."
  type        = number
  default     = 60
}

variable "cognito_refresh_token_validity" {
  description = "Refresh token validity in days."
  type        = number
  default     = 30
}

variable "cognito_domain_prefix" {
  description = <<-EOT
    Prefix for the Cognito hosted-UI domain. The full domain becomes
    "<prefix>.auth.<region>.amazoncognito.com". Must be globally unique
    across all AWS accounts in the region, 1-63 chars, lowercase letters,
    numbers and hyphens, and cannot start/end with a hyphen or use "aws"/"cognito"/"amazon".
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$", var.cognito_domain_prefix))
    error_message = "cognito_domain_prefix must be 1-63 chars, lowercase alphanumeric/hyphens, and not start or end with a hyphen."
  }
}

###############################################################################
# Frontend
###############################################################################

variable "front_end_bucket" {
  description = "Name of the S3 bucket hosting the frontend assets."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class controlling which edge locations are used."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

###############################################################################
# DynamoDB
###############################################################################

variable "products_table_name" {
  description = "Name of the DynamoDB products table."
  type        = string
  default     = "ecommerce-products"
}

variable "carts_table_name" {
  description = "Name of the DynamoDB products table."
  type        = string
  default     = "ecommerce-cart"
}
