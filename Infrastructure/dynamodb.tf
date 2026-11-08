###############################################################################
# DynamoDB: products table
#
# On-demand (PAY_PER_REQUEST) billing so there is no capacity to manage and no
# cost when idle. Partition key is product_id. Point-in-time recovery and
# server-side encryption are enabled as sensible production defaults.
###############################################################################

resource "aws_dynamodb_table" "products" {
  name         = var.products_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "product_id"

  attribute {
    name = "product_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = var.products_table_name
  }
}


resource "aws_dynamodb_table" "carts" {
  name         = var.carts_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = var.products_table_name
  }
}
