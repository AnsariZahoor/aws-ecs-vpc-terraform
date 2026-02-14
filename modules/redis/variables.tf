variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for Redis subnet group"
  type        = list(string)
}

variable "create_redis" {
  description = "Whether to create a new Redis cluster"
  type        = bool
  default     = true
}

variable "existing_redis_cluster_id" {
  description = "ID of an existing Redis cluster to use"
  type        = string
  default     = ""
}

variable "redis_sg_id" {
  description = "ID of the Redis security group"
  type        = string
}
