variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "services" {
  description = "ECS services configuration"
  type = list(object({
    name             = string
    container_port   = number
    cpu              = number
    memory           = number
    desired_count    = number
    container_image  = string
    assign_public_ip = optional(bool, false)
  }))
}

variable "service_subnet_ids" {
  description = "IDs of per-service subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of private subnets (for VPC endpoints)"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "ecs_tasks_sg_id" {
  description = "ID of the ECS tasks security group"
  type        = string
}

variable "vpc_endpoints_sg_id" {
  description = "ID of the VPC endpoints security group"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint address"
  type        = string
}

variable "route_table_ids" {
  description = "IDs of route tables (for S3 gateway endpoint)"
  type        = list(string)
}
