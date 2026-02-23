# Module Patterns Guide

Best practices for designing, structuring, and documenting Terraform/OpenTofu modules.

---

## Module Structure Standards

### Complete Module Layout

```
terraform-aws-vpc/          # Module name with cloud prefix
├── README.md               # Usage documentation
├── LICENSE                 # Module license
├── main.tf                 # Primary resources
├── variables.tf            # Input variables with descriptions
├── outputs.tf              # Output values
├── versions.tf             # Provider version constraints
├── data.tf                 # Data sources (optional)
├── locals.tf               # Local values (optional)
├── examples/
│   ├── minimal/            # Minimal working example
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── complete/           # Full-featured example
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── tests/
    ├── minimal.tftest.hcl  # Tests for minimal example
    └── complete.tftest.hcl # Tests for complete example
```

### File Size Guidelines

| File | Recommended Max | When to Split |
|------|----------------|---------------|
| `main.tf` | 200 lines | Split by resource type (e.g., `s3.tf`, `iam.tf`) |
| `variables.tf` | Any size | Can split by category if very large |
| `outputs.tf` | Any size | Can group by resource type |
| `locals.tf` | 100 lines | Rarely needs splitting |

---

## Variable Design Best Practices

### Variable Block Structure

```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be valid IPv4 CIDR block"
  }

  nullable = false
}
```

### Variable Ordering Within Block

1. **description** (ALWAYS required)
2. **type**
3. **default**
4. **validation**
5. **sensitive** (if true)
6. **nullable** (if false)

### Type Constraints

✅ **DO: Use explicit types**
```hcl
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "subnet_config" {
  description = "Configuration for subnets"
  type = list(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))
}
```

❌ **DON'T: Use `any` type**
```hcl
variable "config" {
  description = "Configuration"
  type        = any  # Too vague, hard to validate
}
```

### Optional Attributes (1.3+)

```hcl
variable "database" {
  description = "Database configuration"
  type = object({
    name              = string
    instance_class    = string
    allocated_storage = optional(number, 20)      # Default: 20
    multi_az          = optional(bool, false)     # Default: false
    backup_retention  = optional(number, 7)       # Default: 7
    tags              = optional(map(string), {}) # Default: {}
  })
}

# Usage - minimal input required
module "db" {
  source = "./modules/database"

  database = {
    name           = "myapp"
    instance_class = "db.t3.micro"
    # All optional fields use defaults
  }
}
```

### Validation Rules

✅ **DO: Validate at boundaries**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string

  validation {
    condition     = can(regex("^[tm][0-9]", var.instance_type))
    error_message = "Instance type must start with t or m (e.g., t3.micro, m5.large)"
  }
}
```

### Sensitive Variables

```hcl
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true  # Never shown in logs/output

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Password must be at least 16 characters"
  }
}
```

### Variable Naming Conventions

✅ **DO:**
- Use descriptive names: `vpc_cidr_block` not `cidr`
- Prefix with context: `database_instance_class` not `instance_class`
- Use underscores: `subnet_ids` not `subnetIds`
- Use plural for lists: `availability_zones` not `availability_zone`

❌ **DON'T:**
- Use generic names: `config`, `settings`, `options`
- Use abbreviations: `az` instead of `availability_zones`
- Mix naming styles: `subnetIDs` and `vpc_id`

### Variable Organization

**In `variables.tf`, group by category:**

```hcl
#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  # ...
}

variable "availability_zones" {
  # ...
}

#------------------------------------------------------------------------------
# Compute Configuration
#------------------------------------------------------------------------------

variable "instance_type" {
  # ...
}

variable "instance_count" {
  # ...
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  # ...
}
```

---

## Output Design Best Practices

### Output Block Structure

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "database_password" {
  description = "Database master password (sensitive)"
  value       = aws_db_instance.this.password
  sensitive   = true  # Hidden from CLI output
}
```

### Output Ordering Within Block

1. **description** (ALWAYS required)
2. **value**
3. **sensitive** (if true)

### What to Output

✅ **DO: Output identifiers and references**
```hcl
output "vpc_id" {
  description = "ID of the VPC for use in other modules"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for placing internal resources"
  value       = aws_subnet.private[*].id
}

output "security_group_id" {
  description = "Security group ID for attaching to instances"
  value       = aws_security_group.this.id
}
```

✅ **DO: Output connection information**
```hcl
output "database_endpoint" {
  description = "Database connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}
```

❌ **DON'T: Output everything**
```hcl
# Don't output unless consumers need it
output "vpc_arn" {
  value = aws_vpc.this.arn  # Rarely needed
}
```

### Grouping Related Outputs

✅ **DO: Return objects for related values**
```hcl
output "database" {
  description = "Database connection information"
  value = {
    endpoint = aws_db_instance.this.endpoint
    port     = aws_db_instance.this.port
    name     = aws_db_instance.this.db_name
    username = aws_db_instance.this.username
  }

  sensitive = true
}

# Usage in consuming module
module "database" {
  source = "./modules/rds"
  # ...
}

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/app/db/endpoint"
  value = module.database.database.endpoint
}
```

### Output Descriptions

✅ **DO: Describe purpose and usage**
```hcl
output "vpc_id" {
  description = "ID of the VPC. Use this when creating resources that need vpc_id parameter."
  value       = aws_vpc.this.id
}
```

❌ **DON'T: Repeat the name**
```hcl
output "vpc_id" {
  description = "The VPC ID"  # Not helpful
  value       = aws_vpc.this.id
}
```

---

## Module Composition Patterns

### Pattern 1: Wrapper Module

**Use case:** Simplify complex upstream modules with opinionated defaults

```hcl
# modules/opinionated-vpc/main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  # Opinionated defaults
  azs             = var.availability_zones
  private_subnets = [for i, az in var.availability_zones : cidrsubnet(var.cidr, 8, i)]
  public_subnets  = [for i, az in var.availability_zones : cidrsubnet(var.cidr, 8, i + 100)]

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "prod"  # Multi-NAT for prod only

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

# Simple interface
variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### Pattern 2: Composite Module

**Use case:** Bundle related resource modules for a complete solution

```hcl
# modules/web-application/main.tf

module "vpc" {
  source = "../networking/vpc"

  name               = var.name
  cidr               = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "alb" {
  source = "../networking/alb"

  name            = var.name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
}

module "ecs_cluster" {
  source = "../compute/ecs-cluster"

  name            = var.name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  alb_arn         = module.alb.arn
}

module "rds" {
  source = "../data/rds"

  name            = var.name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  allowed_sg_ids  = [module.ecs_cluster.security_group_id]
}
```

### Pattern 3: Feature Flags

**Use case:** Optional components controlled by variables

```hcl
variable "create_database" {
  description = "Create RDS database"
  type        = bool
  default     = true
}

variable "create_cache" {
  description = "Create ElastiCache cluster"
  type        = bool
  default     = false
}

module "database" {
  count  = var.create_database ? 1 : 0
  source = "./modules/rds"

  # ...
}

module "cache" {
  count  = var.create_cache ? 1 : 0
  source = "./modules/elasticache"

  # ...
}
```

---

## README Documentation

### Essential Sections

```markdown
# Terraform AWS VPC Module

Brief description of what this module does.

## Features

- ✅ Multi-AZ VPC with public/private subnets
- ✅ NAT Gateway for outbound traffic
- ✅ VPC Flow Logs to S3
- ✅ IPv6 support (optional)

## Usage

### Minimal Example

\`\`\`hcl
module "vpc" {
  source = "github.com/yourorg/terraform-aws-vpc"

  name               = "my-vpc"
  cidr               = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
\`\`\`

### Complete Example

See [examples/complete](examples/complete/) for full configuration.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | `string` | n/a | yes |
| cidr | CIDR block for VPC | `string` | n/a | yes |
| availability_zones | List of AZs | `list(string)` | n/a | yes |
| enable_nat_gateway | Create NAT Gateway | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| private_subnet_ids | List of private subnet IDs |
| public_subnet_ids | List of public subnet IDs |

## Examples

- [Minimal](examples/minimal/) - Basic VPC with defaults
- [Complete](examples/complete/) - All features enabled

## Testing

\`\`\`bash
# Run all tests
terraform test

# Run specific test
terraform test tests/complete.tftest.hcl
\`\`\`

## License

Apache 2.0
```

---

## DO vs DON'T Patterns

### Variables

| ❌ DON'T | ✅ DO |
|----------|-------|
| `variable "cidr" {}` | `variable "vpc_cidr" { description = "..." type = string }` |
| `type = any` | `type = object({ ... })` with explicit structure |
| `default = null` everywhere | Use `optional()` with sensible defaults |
| Generic names (`config`, `settings`) | Specific names (`database_config`, `vpc_settings`) |

### Outputs

| ❌ DON'T | ✅ DO |
|----------|-------|
| `output "id" {}` | `output "vpc_id" { description = "..." }` |
| Output unused values | Only output what consumers need |
| Forget `sensitive = true` | Mark passwords/keys as sensitive |

### Module Structure

| ❌ DON'T | ✅ DO |
|----------|-------|
| 1000-line `main.tf` | Split by resource type |
| No examples | Provide `examples/minimal/` and `examples/complete/` |
| No tests | Add `tests/*.tftest.hcl` |
| No version constraints | Pin versions in `versions.tf` |

### Module Design

| ❌ DON'T | ✅ DO |
|----------|-------|
| One module does everything | Single responsibility modules |
| Hardcode values | Use variables with defaults |
| Create resources conditionally everywhere | Use feature flags sparingly |
| Expose every provider argument | Expose common ones, hardcode sensible defaults |

---

## Module Versioning

### Semantic Versioning

Follow [SemVer](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes

### What Constitutes Breaking Changes

**Breaking changes (MAJOR bump):**
- Removing variables
- Removing outputs
- Changing variable types
- Changing default values that affect existing resources
- Renaming resources (without `moved` blocks)

**Non-breaking (MINOR bump):**
- Adding new variables with defaults
- Adding new outputs
- Adding new optional features
- Adding `moved` blocks for refactoring

### Tagging Releases

```bash
# Tag a release
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0

# Reference in consuming code
module "vpc" {
  source = "github.com/yourorg/terraform-aws-vpc?ref=v1.2.0"
  # ...
}
```

---

## Further Reading

- [Terraform Module Best Practices](https://www.terraform-best-practices.com/code-structure)
- [AWS Terraform Modules](https://github.com/terraform-aws-modules)
- [HashiCorp Module Standards](https://developer.hashicorp.com/terraform/language/modules/develop)
