# ---------------------------------------------------------------------------
# Networking Module
# VPC, subnets, internet gateway, NAT gateways, route tables, elastic IPs
# ---------------------------------------------------------------------------

# --- Data sources for existing resources ---

data "aws_vpc" "existing" {
  count = var.existing_vpc_id != "" ? 1 : 0
  id    = var.existing_vpc_id
}

data "aws_eip" "existing" {
  count = length(var.existing_eip_ids)
  id    = var.existing_eip_ids[count.index]
}

data "aws_subnets" "all" {
  count = var.existing_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }
}

data "aws_subnet" "all" {
  count = var.existing_vpc_id != "" ? length(data.aws_subnets.all[0].ids) : 0
  id    = data.aws_subnets.all[0].ids[count.index]
}

data "aws_internet_gateway" "existing" {
  count = var.existing_vpc_id != "" ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [var.existing_vpc_id]
  }
}

# --- VPC ---

resource "aws_vpc" "main" {
  count = var.existing_vpc_id == "" ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# --- Internet Gateway ---

resource "aws_internet_gateway" "main" {
  count  = var.existing_vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# --- Subnets ---

resource "aws_subnet" "public" {
  count = var.existing_vpc_id == "" ? length(var.public_subnet_cidrs) : 0

  vpc_id            = local.vpc_id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private" {
  count = var.existing_vpc_id == "" ? length(var.private_subnet_cidrs) : 0

  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "service" {
  count = length(var.services)

  vpc_id            = local.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.service_subnet_offset)
  availability_zone = var.availability_zones[0]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.services[count.index].name}-subnet"
  })
}

# --- Elastic IPs ---

resource "aws_eip" "nat" {
  count = var.create_nat_gateways && var.use_elastic_ip && length(var.existing_eip_ids) == 0 ? length(var.services) : 0

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eip-nat-${count.index + 1}"
  })
}

# --- NAT Gateways ---

resource "aws_nat_gateway" "main" {
  count = var.create_nat_gateways && var.use_elastic_ip ? length(var.services) : 0

  subnet_id     = length(local.public_subnet_ids) > 0 ? local.public_subnet_ids[count.index % length(local.public_subnet_ids)] : null
  allocation_id = length(var.existing_eip_ids) > 0 ? data.aws_eip.existing[count.index].id : aws_eip.nat[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# --- Route Tables ---

resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.existing_vpc_id != "" ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id

  depends_on = [aws_route_table.public]
}

resource "aws_route_table" "private" {
  count  = length(var.services)
  vpc_id = local.vpc_id

  # NAT gateway route (static outbound IPs)
  dynamic "route" {
    for_each = var.create_nat_gateways && var.use_elastic_ip ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  # Direct internet gateway route (no static IP)
  dynamic "route" {
    for_each = !var.use_elastic_ip ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = var.existing_vpc_id != "" ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.use_elastic_ip ? "private" : "public"}-rt-${count.index + 1}"
  })
}

# --- Route Table Associations ---

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnet_ids)
  subnet_id      = local.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "service" {
  count          = length(var.services)
  subnet_id      = aws_subnet.service[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Locals ---

locals {
  vpc_id = var.existing_vpc_id != "" ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id

  existing_public_subnets = var.existing_vpc_id != "" ? [
    for subnet in data.aws_subnet.all : subnet.id
    if length(regexall("public", lower(subnet.tags["Name"]))) > 0
  ] : []

  existing_private_subnets = var.existing_vpc_id != "" ? [
    for subnet in data.aws_subnet.all : subnet.id
    if length(regexall("private", lower(subnet.tags["Name"]))) > 0
  ] : []

  public_subnet_ids  = length(local.existing_public_subnets) > 0 ? local.existing_public_subnets : aws_subnet.public[*].id
  private_subnet_ids = length(local.existing_private_subnets) > 0 ? local.existing_private_subnets : aws_subnet.private[*].id
}
