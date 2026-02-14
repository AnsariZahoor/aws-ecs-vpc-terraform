# ---------------------------------------------------------------------------
# Root Outputs
# ---------------------------------------------------------------------------

# --- Networking ---

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "service_subnet_ids" {
  description = "IDs of per-service subnets"
  value       = module.networking.service_subnet_ids
}

output "elastic_ips" {
  description = "Elastic IP address for NAT Gateway"
  value       = module.networking.nat_eip
}

# --- ECS ---

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "Names of the ECS services"
  value       = module.ecs.service_names
}

output "shared_task_definition_arn" {
  description = "ARN of the shared task definition"
  value       = module.ecs.task_definition_arn
}

# --- Redis ---

output "redis_endpoint" {
  description = "Redis endpoint address"
  value       = module.redis.redis_endpoint
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.redis_port
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = module.security.redis_sg_id
}

# --- Meta ---

output "region_deployment" {
  description = "Region-specific deployment details"
  value = {
    region             = var.aws_region
    availability_zones = var.availability_zones
    elastic_ips        = module.networking.elastic_ips
  }
}
