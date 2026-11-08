locals {
  # Consistent name prefix for all resources, e.g. "ecommerce-dev".
  name_prefix = "${var.project}-${var.environment}"

  # Tags merged on top of provider default_tags where resources need extras.
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
