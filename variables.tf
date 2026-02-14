# ---------------------------------------------------------------------------
# Root Variables
# ---------------------------------------------------------------------------

# --- Project ---

variable "project_name" {
  description = "Name of the project (used as resource name prefix)"
  type        = string
  default     = "ecs-vpc-infra"
}

variable "project" {
  description = "Project identifier (used in tags)"
  type        = string
  default     = "ecs-vpc-infra"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
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

variable "allow_incoming_connections" {
  description = "Whether to allow inbound HTTP/HTTPS to ECS services"
  type        = bool
  default     = false
}

# --- Existing Resources (leave empty to create new) ---

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use"
  type        = string
  default     = ""
}

variable "existing_eip_ids" {
  description = "List of existing Elastic IP allocation IDs for NAT gateways"
  type        = list(string)
  default     = []
}

variable "existing_redis_cluster_id" {
  description = "ID of an existing Redis cluster to use"
  type        = string
  default     = ""
}

# --- ECS Services ---

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

  default = [
    {
      name            = "api"
      container_port  = 3000
      cpu             = 256
      memory          = 512
      desired_count   = 1
      container_image = "node:18-alpine"
    },
    {
      name            = "worker"
      container_port  = 3001
      cpu             = 256
      memory          = 512
      desired_count   = 1
      container_image = "node:18-alpine"
    }
  ]
}

# --- Redis ---

variable "create_redis" {
  description = "Whether to create a new Redis cluster"
  type        = bool
  default     = true
}
