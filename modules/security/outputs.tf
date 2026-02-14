output "ecs_tasks_sg_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "vpc_endpoints_sg_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

output "external_access_sg_id" {
  description = "ID of the external access security group"
  value       = aws_security_group.external_access.id
}

output "redis_sg_id" {
  description = "ID of the Redis security group"
  value       = try(aws_security_group.redis[0].id, "")
}
