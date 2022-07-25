locals {

  max_subnet_length = max(
    length(var.private_subnets),
  )
  nat_gateway_count = var.single_nat_gateway ? 1 : local.max_subnet_length
  nat_zones         = toset(slice(keys(var.private_subnets), 0, local.nat_gateway_count))

  tags = {
    Environment = lower(var.environment.full)
  }

}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = "false"
  enable_classiclink               = "false"
  tags = merge(
    {
      Name = title(var.environment.short)
    },
    local.tags
  )
}

// Public networks (Internet)

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = "${var.environment.short}-Internet-Gateway"
    },
    local.tags
  )
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = "${var.region}${each.key}"

  tags = merge(
    {
      Name = title(format("%s-Public-%s", var.environment.short, each.key))
    },
    local.tags,
    var.public_subnet_tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = title("${var.environment.short}-Public")
    },
    local.tags
  )
}

resource "aws_route" "default_route_public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  depends_on = [
    aws_internet_gateway.this
  ]
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[each.key].id
}

// Private networks (NAT)
resource "aws_eip" "nat" {
  for_each = local.nat_zones

  vpc = true
  tags = merge(
    {
      Name = "${title(var.environment.short)}-NAT-IP-${title(each.key)}"
    },
    local.tags
  )
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_zones

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    {
      "Name" = title(format("${var.environment.short}-NAT-%s", each.key))
    },
    local.tags
  )

  depends_on = [
    aws_internet_gateway.this,
    aws_subnet.private
  ]
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = "${var.region}${each.key}"

  tags = merge(
    {
      Name = title(format("%s-Private-%s", var.environment.short, each.key))
    },
    local.tags,
    var.private_subnet_tags
  )
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.vpc.id

  tags = merge(
    {
      Name = title(format("%s-Private-%s", var.environment.short, each.key))
    },
    local.tags
  )
}

resource "aws_route" "default_route_private" {
  for_each               = var.private_subnets
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"

  //HARDCODE
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this["a"].id : aws_nat_gateway.this[each.key].id

  depends_on = [
    aws_eip.nat,
    aws_nat_gateway.this
  ]
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets
  route_table_id = aws_route_table.private[each.key].id
  subnet_id      = aws_subnet.private[each.key].id
}

// Local networks
resource "aws_subnet" "local" {
  for_each = var.local_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = "${var.region}${each.key}"

  tags = merge(
    {
      Name = title(format("%s-Local-%s", var.environment.short, each.key))
    },
    local.tags
  )
}

resource "aws_route_table" "local" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = title("${var.environment.short}-Local")
    },
    local.tags
  )
}

resource "aws_route_table_association" "local" {
  for_each       = var.local_subnets
  route_table_id = aws_route_table.local.id
  subnet_id      = aws_subnet.local[each.key].id
}
