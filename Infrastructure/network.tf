###############################################################################
# VPC + Internet Gateway
###############################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

###############################################################################
# Subnets (3 tiers, one subnet per AZ in each tier)
#
#   public      -> ALB + NAT Gateway, routes to Internet Gateway
#   app (private)-> application / ECS, egress via NAT Gateway
#   db  (private)-> PostgreSQL / RDS, fully isolated (local route only)
###############################################################################

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-app-${var.availability_zones[count.index]}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-db-${var.availability_zones[count.index]}"
    Tier = "private-db"
  }
}

###############################################################################
# NAT Gateways (live in the public subnets)
#
# nat_gateway_per_az = false -> single shared NAT Gateway in public AZ-a (diagram)
# nat_gateway_per_az = true  -> one NAT Gateway per public subnet (HA)
###############################################################################

locals {
  nat_gateway_count = var.nat_gateway_per_az ? length(aws_subnet.public) : 1
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-natgw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

###############################################################################
# Route table: PUBLIC  (10.10.0.0/16 -> local, 0.0.0.0/0 -> Internet Gateway)
###############################################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Route table: APP  (10.10.0.0/16 -> local, 0.0.0.0/0 -> NAT Gateway)
###############################################################################

resource "aws_route_table" "app" {
  count = local.nat_gateway_count

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${local.name_prefix}-app-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "app" {
  count = length(aws_subnet.app)

  subnet_id = aws_subnet.app[count.index].id
  # With a single NAT Gateway all app subnets share route table index 0.
  route_table_id = aws_route_table.app[count.index % local.nat_gateway_count].id
}

###############################################################################
# Route table: DB  (10.10.0.0/16 -> local ONLY, fully isolated)
###############################################################################

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  # No 0.0.0.0/0 route. The implicit local route keeps the DB tier reachable
  # only from within the VPC.

  tags = {
    Name = "${local.name_prefix}-db-rt"
  }
}

resource "aws_route_table_association" "db" {
  count = length(aws_subnet.db)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

###############################################################################
# DB subnet group (for RDS / PostgreSQL placement in the isolated tier)
###############################################################################

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}
