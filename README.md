# AWS ECS VPC Infrastructure — Terraform

Production-grade, modular Terraform project that provisions a complete AWS networking and container orchestration stack. Deploys ECS Fargate services inside isolated VPC subnets with optional NAT Gateways, ElastiCache Redis, and VPC Endpoints — all fully configurable.

## Architecture
![image](https://github.com/AnsariZahoor/media-storage/blob/main/private.png)

![image](https://github.com/AnsariZahoor/media-storage/blob/main/public.png)

## Modules

The infrastructure is split into five focused modules:

| Module | Description |
|---|---|
| **`modules/networking`** | VPC, public/private/service subnets, IGW, NAT Gateways, EIPs, route tables |
| **`modules/security`** | Security groups for ECS tasks, VPC endpoints, external access, Redis |
| **`modules/ecs`** | ECS Fargate cluster, services, shared task definition, CloudWatch Logs, VPC endpoints |
| **`modules/redis`** | ElastiCache Redis cluster, subnet group, parameter group |
| **`modules/iam`** | ECS task execution role and task role with least-privilege policies |

## Key Design Decisions

- **Outbound-only by default** — No load balancer, no inbound traffic unless explicitly enabled via `allow_incoming_connections`
- **Per-service isolation** — Each ECS service gets its own subnet and route table
- **Flexible networking** — Toggle between NAT Gateway (static IPs) and direct internet via public subnets
- **Existing resource support** — Can plug into an existing VPC, Redis cluster, or Elastic IPs
- **VPC Endpoints** — Keeps ECR image pulls and log shipping within the AWS network, reducing NAT costs
- **Modular architecture** — Clean separation of concerns, each module is independently testable

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0.0
- AWS CLI configured with appropriate credentials
- An AWS account with permissions (see [`docs/iam-policy.json`](docs/iam-policy.json))

## Quick Start

1. **Clone the repo**

```bash
git clone https://github.com/<your-username>/aws-ecs-vpc-terraform.git
cd aws-ecs-vpc-terraform
```

2. **Create a `terraform.tfvars` file** (see [`terraform.tfvars.example`](terraform.tfvars.example))

```hcl
project_name       = "my-project"
project            = "my-project"
aws_region         = "us-east-1"
aws_profile        = "default"
environment        = "dev"
availability_zones = ["us-east-1a", "us-east-1b"]

services = [
  {
    name            = "api"
    container_port  = 3000
    cpu             = 256
    memory          = 512
    desired_count   = 1
    container_image = "node:18-alpine"
  }
]
```

3. **Deploy**

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

### Networking Modes

| Mode | Variables | Use Case |
|---|---|---|
| **NAT Gateway + EIP** | `use_elastic_ip = true`, `create_nat_gateways = true` | Need static outbound IPs (e.g., IP whitelisting) |
| **Direct Internet** | `use_elastic_ip = false` | Cost-effective, no static IP needed |
| **Existing VPC** | `existing_vpc_id = "vpc-xxx"` | Integrate into pre-existing network |
| **Existing EIPs** | `existing_eip_ids = ["eipalloc-xxx"]` | Reuse pre-allocated Elastic IPs |

### Redis

| Variable | Default | Description |
|---|---|---|
| `create_redis` | `true` | Create a new ElastiCache Redis cluster |
| `existing_redis_cluster_id` | `""` | Use an existing Redis cluster instead |

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `ecs_cluster_id` / `ecs_cluster_name` | ECS cluster identifiers |
| `private_subnet_ids` / `service_subnet_ids` | Subnet IDs |
| `elastic_ips` | NAT Gateway Elastic IP(s) |
| `redis_endpoint` / `redis_port` | Redis connection details |
| `shared_task_definition_arn` | Task definition ARN |
| `ecs_service_names` | Deployed ECS service names |

## Project Structure

```
.
├── main.tf                          # Provider, backend, module composition
├── variables.tf                     # Root input variables
├── outputs.tf                       # Root outputs
├── terraform.tfvars.example         # Example variable values
├── .gitignore
├── docs/
│   └── iam-policy.json              # Minimum IAM policy for deployment
└── modules/
    ├── networking/
    │   ├── main.tf                  # VPC, subnets, IGW, NAT, routes
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/
    │   ├── main.tf                  # Security groups
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ecs/
    │   ├── main.tf                  # Cluster, services, task defs, VPC endpoints
    │   ├── variables.tf
    │   └── outputs.tf
    ├── redis/
    │   ├── main.tf                  # ElastiCache Redis
    │   ├── variables.tf
    │   └── outputs.tf
    └── iam/
        ├── main.tf                  # IAM roles and policies
        ├── variables.tf
        └── outputs.tf
```

## Cleanup

```bash
terraform destroy
```

## License

MIT
