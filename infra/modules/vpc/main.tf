resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  for_each = zipmap(var.azs, var.public_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${var.name}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = zipmap(var.azs, var.private_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

locals {
  # One private route table per AZ in per_az mode, otherwise one shared table.
  private_route_table_azs = var.nat_mode == "per_az" ? var.azs : [var.azs[0]]
  nat_azs                 = var.nat_mode == "none" ? [] : local.private_route_table_azs
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = toset(local.private_route_table_azs)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.nat_mode == "per_az" ? "${var.name}-private-${each.key}" : "${var.name}-private"
  }
}

# Separate resource rather than an inline route: with an inline dynamic block,
# setting nat_mode to none would leave the old route in the table.
resource "aws_route" "private_nat" {
  for_each = toset(local.nat_azs)

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[var.nat_mode == "per_az" ? each.key : var.azs[0]].id
}

# Adopts the main route table AWS creates with the VPC and keeps it empty.
resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id
  route                  = []

  tags = {
    Name = "${var.name}-main-unused"
  }
}

# Adopts the default security group AWS creates with the VPC and removes all its rules.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-default-unused"
  }
}
