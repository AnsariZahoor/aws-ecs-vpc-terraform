output "redis_endpoint" {
  description = "Redis endpoint address"
  value       = local.redis_endpoint
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}
