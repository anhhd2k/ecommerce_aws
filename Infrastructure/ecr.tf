###############################################################################
# ECR repositories
#
# One container image repository per backend microservice
# (product, cart, user, order). Images are scanned on push and tags are
# immutable to guarantee deployments reference a fixed image digest.
#
# A lifecycle policy keeps the last N images and expires untagged images to
# control storage cost.
###############################################################################

locals {
  ecr_services = ["product", "cart", "user", "order"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.ecr_services)

  name                 = "ecommerce/${each.key}-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${local.name_prefix}-${each.key}-ecr"
    Service = each.key
  }
}

###############################################################################
# Lifecycle policy: retain the most recent images, expire the rest
###############################################################################

resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days."
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the most recent ${var.ecr_image_retention_count} tagged images."
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.ecr_image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
