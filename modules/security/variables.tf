variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (for Redis ingress rule)"
  type        = string
}

variable "allow_incoming_connections" {
  description = "Whether to allow inbound HTTP/HTTPS to ECS tasks"
  type        = bool
  default     = false
}

variable "create_redis" {
  description = "Whether to create Redis security group"
  type        = bool
  default     = true
}
