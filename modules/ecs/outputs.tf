output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_names" {
  description = "Names of the ECS services"
  value       = aws_ecs_service.main[*].name
}

output "task_definition_arn" {
  description = "ARN of the shared task definition"
  value       = aws_ecs_task_definition.shared.arn
}
