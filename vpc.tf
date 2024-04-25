module "label_vpc" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "vpc"
  attributes = ["main"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = module.label_vpc.tags
}

# =========================
# Create your subnets here
# =========================


module "label_public_subnet" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "subnet"
  attributes = ["public"]
}

module "label_private_subnet" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "subnet"
  attributes = ["private"]
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = module.label_public_subnet.tags
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = module.label_private_subnet.tags

}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = module.label_vpc.tags
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = module.label_public_subnet.tags
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
