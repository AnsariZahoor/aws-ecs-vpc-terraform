output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = local.private_subnet_ids
}

output "service_subnet_ids" {
  description = "IDs of per-service subnets"
  value       = aws_subnet.service[*].id
}

output "elastic_ips" {
  description = "All NAT Gateway Elastic IPs"
  value       = aws_eip.nat[*].public_ip
}

output "nat_eip" {
  description = "Primary NAT Gateway Elastic IP"
  value       = length(var.existing_eip_ids) > 0 ? data.aws_eip.existing[0].public_ip : try(aws_eip.nat[0].public_ip, null)
}

output "route_table_ids" {
  description = "IDs of private route tables"
  value       = aws_route_table.private[*].id
}
