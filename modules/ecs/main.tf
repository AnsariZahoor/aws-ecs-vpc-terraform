# ---------------------------------------------------------------------------
# ECS Module
# Cluster, services, task definitions, CloudWatch logs, VPC endpoints
# ---------------------------------------------------------------------------

# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.common_tags
}

# --- CloudWatch Log Group ---

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}-cluster"
  retention_in_days = 30

  tags = var.common_tags
}

# --- Shared Task Definition ---

resource "aws_ecs_task_definition" "shared" {
  family                   = "${var.name_prefix}-shared-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app-primary"
      image     = "node:18-alpine"
      essential = true

      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
        protocol      = "tcp"
      }]

      environment = [
        { name = "NODE_ENV", value = var.environment },
        { name = "SERVICE_NAME", value = "process1" },
        { name = "REDIS_HOST", value = var.redis_endpoint },
        { name = "REDIS_PORT", value = "6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "process1"
        }
      }

      command = [
        "node", "-e",
        "const http = require('http'); const net = require('net'); const os = require('os'); const server = http.createServer((req, res) => { res.writeHead(200); res.end('Hello from Process 1 - Hostname: ' + os.hostname() + '\\n'); }); server.listen(3000, () => { console.log('Process 1 started on port 3000'); }); const checkRedis = () => { const client = new net.Socket(); client.setTimeout(5000); client.connect(process.env.REDIS_PORT || 6379, process.env.REDIS_HOST, () => { console.log('Redis connection successful'); client.destroy(); }); client.on('error', (err) => { console.log('Redis connection failed:', err.message); }); client.on('timeout', () => { console.log('Redis connection timeout'); client.destroy(); }); }; checkRedis(); setInterval(checkRedis, 30000);"
      ]
    },
    {
      name      = "app-secondary"
      image     = "node:18-alpine"
      essential = true

      portMappings = [{
        containerPort = 3100
        hostPort      = 3100
        protocol      = "tcp"
      }]

      environment = [
        { name = "NODE_ENV", value = var.environment },
        { name = "SERVICE_NAME", value = "process2" },
        { name = "REDIS_HOST", value = var.redis_endpoint },
        { name = "REDIS_PORT", value = "6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "process2"
        }
      }

      command = [
        "node", "-e",
        "const http = require('http'); const net = require('net'); const os = require('os'); const server = http.createServer((req, res) => { res.writeHead(200); res.end('Hello from Process 2 - Hostname: ' + os.hostname() + '\\n'); }); server.listen(3100, () => { console.log('Process 2 started on port 3100'); }); const checkRedis = () => { const client = new net.Socket(); client.setTimeout(5000); client.connect(process.env.REDIS_PORT || 6379, process.env.REDIS_HOST, () => { console.log('Redis connection successful'); client.destroy(); }); client.on('error', (err) => { console.log('Redis connection failed:', err.message); }); client.on('timeout', () => { console.log('Redis connection timeout'); client.destroy(); }); }; checkRedis(); setInterval(checkRedis, 30000);"
      ]
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-shared-task-def"
  })
}

# --- ECS Services ---

resource "aws_ecs_service" "main" {
  count           = length(var.services)
  name            = "${var.name_prefix}-${var.services[count.index].name}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.shared.family
  desired_count   = var.services[count.index].desired_count
  propagate_tags  = "TASK_DEFINITION"
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.service_subnet_ids[count.index]]
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = var.services[count.index].assign_public_ip
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.services[count.index].name}-service"
  })
}

# --- VPC Endpoints (for ECR image pulls & log shipping) ---

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_sg_id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_sg_id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_sg_id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-logs-endpoint"
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}
