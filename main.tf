# ---------------------------------------------------------------------------
# Root Configuration
# Provider, backend, and module composition
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # Configure your remote backend here
  # backend "s3" {
  #   bucket  = "your-tfstate-bucket"
  #   key     = "ecs-vpc/terraform.tfstate"
  #   region  = "us-east-1"
  #   encrypt = true
  # }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = var.project_name
  common_tags = {
    Project     = lower(var.project)
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

# --- Networking ---
module "networking" {
  source = "./modules/networking"

  name_prefix           = local.name_prefix
  common_tags           = local.common_tags
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  availability_zones    = var.availability_zones
  existing_vpc_id       = var.existing_vpc_id
  existing_eip_ids      = var.existing_eip_ids
  services              = var.services
  use_elastic_ip        = var.use_elastic_ip
  create_nat_gateways   = var.create_nat_gateways
  service_subnet_offset = var.service_subnet_offset
}

# --- Security ---
module "security" {
  source = "./modules/security"

  name_prefix                = local.name_prefix
  common_tags                = local.common_tags
  vpc_id                     = module.networking.vpc_id
  vpc_cidr                   = var.vpc_cidr
  allow_incoming_connections = var.allow_incoming_connections
  create_redis               = var.create_redis
}

# --- IAM ---
module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

# --- Redis ---
module "redis" {
  source = "./modules/redis"

  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
  private_subnet_ids        = module.networking.private_subnet_ids
  create_redis              = var.create_redis
  existing_redis_cluster_id = var.existing_redis_cluster_id
  redis_sg_id               = module.security.redis_sg_id
}

# --- ECS ---
module "ecs" {
  source = "./modules/ecs"

  name_prefix         = local.name_prefix
  common_tags         = local.common_tags
  aws_region          = var.aws_region
  environment         = var.environment
  services            = var.services
  service_subnet_ids  = module.networking.service_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  vpc_id              = module.networking.vpc_id
  ecs_tasks_sg_id     = module.security.ecs_tasks_sg_id
  vpc_endpoints_sg_id = module.security.vpc_endpoints_sg_id
  execution_role_arn  = module.iam.execution_role_arn
  task_role_arn       = module.iam.task_role_arn
  redis_endpoint      = module.redis.redis_endpoint
  route_table_ids     = module.networking.route_table_ids
}
