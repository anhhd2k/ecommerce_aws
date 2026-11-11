###############################################################################
# SSM Parameter Store: database connection settings
#
# A single for_each builds all parameters from a local map. Each entry carries
# its value and type (String for non-secrets, SecureString for the password).
#
# Parameters are namespaced under a hierarchy so the app / IAM policies can
# grant access with a path prefix, e.g.:
#   /ecommerce/dev/db/*
#
# NOTE: For a production database password, AWS Secrets Manager (with
# automatic rotation) is generally preferred over Parameter Store. This uses
# SecureString per the request.
###############################################################################

locals {
  db_param_prefix = "/${var.project}/${var.environment}/db"

  db_parameters = {
    host = {
      value       = aws_db_instance.postgres.address
      type        = "String"
      description = "Database host / endpoint."
    }
    port = {
      value       = tostring(aws_db_instance.postgres.port)
      type        = "String"
      description = "Database port."
    }
    name = {
      value       = aws_db_instance.postgres.db_name
      type        = "String"
      description = "Database name."
    }
    username = {
      value       = aws_db_instance.postgres.username
      type        = "String"
      description = "Database username."
    }
    password = {
      value       = random_password.db_master.result
      type        = "SecureString"
      description = "Database password (KMS-encrypted)."
    }
  }
}

resource "aws_ssm_parameter" "db" {
  for_each = local.db_parameters

  name        = "${local.db_param_prefix}/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  tags = {
    Name = "${local.name_prefix}-db-${each.key}"
  }
}
