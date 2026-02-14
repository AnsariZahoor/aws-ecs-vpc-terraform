variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use (leave empty to create new)"
  type        = string
  default     = ""
}

variable "existing_eip_ids" {
  description = "List of existing Elastic IP allocation IDs for NAT gateways"
  type        = list(string)
  default     = []
}

variable "services" {
  description = "List of ECS service configurations (used for subnet/NAT count)"
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

variable "use_elastic_ip" {
  description = "Use NAT Gateways with Elastic IPs for static outbound IPs"
  type        = bool
  default     = false
}

variable "create_nat_gateways" {
  description = "Whether to create NAT gateways"
  type        = bool
  default     = true
}

variable "service_subnet_offset" {
  description = "Starting offset for service subnet CIDRs"
  type        = number
  default     = 20
}
