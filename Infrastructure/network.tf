# resource "aws_vpc" "main_vpc" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   tags = {
#     Name = "ecom-main-vpc"
#   }
# }

# resource "aws_internet_gateway" "main_igw" {
#   vpc_id = aws_vpc.main_vpc.id

#   tags = {
#     Name = "ecom-main-igw"
#   }
# }

# resource "aws_subnet" "public_subnets" {
#   count = length(var.public_subnet_cidrs)

#   vpc_id                  = aws_vpc.main_vpc.id
#   cidr_block              = var.public_subnet_cidrs[count.index]
#   availability_zone       = var.availability_zones[count.index]
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "ecom-public-subnet-${count.index + 1}"
#   }
# }

# resource "aws_subnet" "private_subnets" {
#   count = length(var.private_subnet_cidrs)

#   vpc_id            = aws_vpc.main_vpc.id
#   cidr_block        = var.private_subnet_cidrs[count.index]
#   availability_zone = var.availability_zones[count.index]

#   tags = {
#     Name = "ecom-private-subnet-${count.index + 1}"
#   }
# }

# resource "aws_eip" "nat_eip" {
#   domain = "vpc"

#   tags = {
#     Name = "ecom-nat-eip-1a"
#   }

#   depends_on = [aws_internet_gateway.main_igw]
# }

# # Single NAT Gateway placed in the public subnet located in AZ "1a".
# resource "aws_nat_gateway" "main_natgw" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public_subnets[0].id
#   tags = {
#     Name = "ecom-natgw-1a"
#   }

#   depends_on = [aws_internet_gateway.main_igw]
# }

# resource "aws_route_table" "main_rt" {
#   vpc_id = aws_vpc.main_vpc.id

#   # The local route (VPC CIDR -> local) is created automatically by AWS.

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main_igw.id
#   }

#   tags = {
#     Name = "ecom-main-rt"
#   }
# }

# resource "aws_route_table_association" "public_rt_assoc" {
#   count = length(aws_subnet.public_subnets)

#   subnet_id      = aws_subnet.public_subnets[count.index].id
#   route_table_id = aws_route_table.main_rt.id
# }

# resource "aws_route_table" "rt_natgw" {
#   vpc_id = aws_vpc.main_vpc.id

#   # The local route (VPC CIDR -> local) is created automatically by AWS.

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.main_natgw.id
#   }

#   tags = {
#     Name = "ecom-natgw-rt"
#   }
# }

# resource "aws_route_table_association" "private_rt_assoc" {

#   subnet_id      = aws_subnet.private_subnets[0].id
#   route_table_id = aws_route_table.rt_natgw.id
# }