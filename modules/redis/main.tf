# ---------------------------------------------------------------------------
# Redis Module
# ElastiCache Redis cluster, subnet group, parameter group
# ---------------------------------------------------------------------------

data "aws_elasticache_cluster" "existing" {
  count      = !var.create_redis && var.existing_redis_cluster_id != "" ? 1 : 0
  cluster_id = var.existing_redis_cluster_id
}

resource "aws_elasticache_subnet_group" "main" {
  count = var.create_redis ? 1 : 0

  name       = replace("${var.name_prefix}-redis-subnet-group", "_", "-")
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-redis-subnet-group"
  })
}

resource "aws_elasticache_parameter_group" "main" {
  count = var.create_redis ? 1 : 0

  name   = replace("${var.name_prefix}-redis-params", "_", "-")
  family = "redis7"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-redis-params"
  })
}

resource "aws_elasticache_cluster" "main" {
  count = var.create_redis ? 1 : 0

  cluster_id           = lower(replace("${var.name_prefix}-redis-cluster", "_", "-"))
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.main[0].name
  subnet_group_name    = aws_elasticache_subnet_group.main[0].name
  security_group_ids   = [var.redis_sg_id]
  port                 = 6379
  engine_version       = "7.1"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-redis"
  })
}

locals {
  redis_endpoint = (
    var.create_redis
    ? try(aws_elasticache_cluster.main[0].cache_nodes[0].address, "")
    : (
      var.existing_redis_cluster_id != ""
      ? try(data.aws_elasticache_cluster.existing[0].cache_nodes[0].address, "")
      : ""
    )
  )
}
