# Code Patterns Guide

Detailed patterns and best practices for writing clean, maintainable Terraform/OpenTofu code.

---

## Module Types & Hierarchy

### Module Classification

| Type | When to Use | Scope | Example |
|------|-------------|-------|---------|
| **Resource Module** | Single logical group of connected resources | VPC + subnets, Security group + rules | `terraform-aws-vpc` |
| **Infrastructure Module** | Collection of resource modules for a purpose | Multiple resource modules in one region/account | `app-infrastructure` |
| **Composition** | Complete infrastructure | Spans multiple regions/accounts | `production-environment` |

### Hierarchy in Practice

```
Composition (environments/prod/)
└── Infrastructure Module (modules/app-infrastructure/)
    ├── Resource Module: VPC (modules/networking/vpc/)
    ├── Resource Module: RDS (modules/data/rds/)
    └── Resource Module: ECS (modules/compute/ecs/)
```

**Design principle from terraform-best-practices.com:**
- Keep modules **small and focused** (single responsibility)
- Separate **environments** from **modules**
- Use `examples/` as both documentation and test fixtures

---

## Block Ordering & Structure

### Resource Block Ordering (Strict)

```hcl
resource "aws_nat_gateway" "this" {
  # 1. count or for_each FIRST (blank line after)
  count = var.create_nat_gateway ? 1 : 0

  # 2. Other arguments (alphabetical recommended)
  allocation_id = aws_eip.this[0].id
  subnet_id     = aws_subnet.public[0].id

  # 3. tags as last real argument
  tags = {
    Name = "${var.name}-nat"
  }

  # 4. depends_on after tags (if needed)
  depends_on = [aws_internet_gateway.this]

  # 5. lifecycle at the very end (if needed)
  lifecycle {
    create_before_destroy = true
  }
}
```

**Why this order:**
- `count`/`for_each` determines resource existence → must be first
- `tags` are metadata → near the end
- `depends_on` is relationship → after resource config
- `lifecycle` affects Terraform behavior → absolute end

### Variable Block Ordering

```hcl
variable "environment" {
  # 1. description (ALWAYS required)
  description = "Environment name for resource tagging"

  # 2. type
  type = string

  # 3. default
  default = "dev"

  # 4. validation
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }

  # 5. nullable (when setting to false)
  nullable = false
}
```

### Output Block Ordering

```hcl
output "vpc_id" {
  # 1. description (ALWAYS required)
  description = "ID of the VPC"

  # 2. value
  value = aws_vpc.this.id

  # 3. sensitive (if needed)
  sensitive = false
}
```

---

## Count vs For_Each: Deep Dive

### Quick Decision Guide

| Scenario | Use | Why |
|----------|-----|-----|
| Boolean condition (create or don't) | `count = condition ? 1 : 0` | Simple on/off toggle |
| Simple numeric replication | `count = 3` | Fixed number of identical resources |
| Items may be reordered/removed | `for_each = toset(list)` | Stable resource addresses |
| Reference by key | `for_each = map` | Named access to resources |
| Multiple named resources | `for_each` | Better maintainability |

### Boolean Conditions

✅ **Best practice:**
```hcl
resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0
  # ...
}

# Reference
resource "aws_route" "private_nat_gateway" {
  count = var.create_nat_gateway ? 1 : 0

  nat_gateway_id = aws_nat_gateway.this[0].id
  # ...
}
```

❌ **Avoid:**
```hcl
# Don't use for_each for simple boolean
resource "aws_nat_gateway" "this" {
  for_each = var.create_nat_gateway ? toset(["this"]) : toset([])
  # Unnecessarily complex
}
```

### Stable Addressing

✅ **for_each - Removal is safe:**
```hcl
resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)
  # ["us-east-1a", "us-east-1b", "us-east-1c"]

  availability_zone = each.key
  # ...
}

# Addresses:
# aws_subnet.private["us-east-1a"]
# aws_subnet.private["us-east-1b"]
# aws_subnet.private["us-east-1c"]

# If you remove "us-east-1b", only that subnet is destroyed
```

❌ **count - Removal causes recreation:**
```hcl
resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  # ["us-east-1a", "us-east-1b", "us-east-1c"]

  availability_zone = var.availability_zones[count.index]
  # ...
}

# Addresses:
# aws_subnet.private[0]  # us-east-1a
# aws_subnet.private[1]  # us-east-1b
# aws_subnet.private[2]  # us-east-1c

# If you remove "us-east-1b" from the list:
# [0] stays us-east-1a (unchanged)
# [1] becomes us-east-1c (RECREATED - was [2])
# [2] is destroyed
```

### Map-Based for_each

```hcl
variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    "public_1" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    }
    "public_2" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  }
}

resource "aws_subnet" "public" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key  # "public_1", "public_2"
  }
}
```

### Migration: count → for_each

**Before (count):**
```hcl
resource "aws_subnet" "private" {
  count = 3

  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  # ...
}
```

**After (for_each):**
```hcl
locals {
  subnet_keys = ["subnet_0", "subnet_1", "subnet_2"]
}

resource "aws_subnet" "private" {
  for_each = toset(local.subnet_keys)

  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(local.subnet_keys, each.key))
  # ...
}
```

**Migration command:**
```bash
# Move state
terraform state mv 'aws_subnet.private[0]' 'aws_subnet.private["subnet_0"]'
terraform state mv 'aws_subnet.private[1]' 'aws_subnet.private["subnet_1"]'
terraform state mv 'aws_subnet.private[2]' 'aws_subnet.private["subnet_2"]'
```

---

## Locals for Dependency Management

### Problem: Unpredictable Deletion Order

When destroying infrastructure, Terraform may delete resources in an order that causes errors.

**Example: VPC with secondary CIDR blocks**

```hcl
# ❌ Problem: Subnets may be deleted after CIDR association
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = var.add_secondary_cidr ? 1 : 0

  vpc_id     = aws_vpc.this.id
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id  # Direct reference
  cidr_block = "10.1.0.0/24"    # Uses secondary CIDR
}

# On destroy:
# 1. CIDR association might be removed first
# 2. Subnet still exists but CIDR is gone → ERROR
```

### Solution: Use try() in Locals

```hcl
# ✅ Solution: Force deletion order with try()
locals {
  # References secondary CIDR first, falling back to VPC
  # This creates implicit dependency: subnets → CIDR → VPC
  vpc_id = try(
    aws_vpc_ipv4_cidr_block_association.this[0].vpc_id,
    aws_vpc.this.id,
    ""
  )
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = var.add_secondary_cidr ? 1 : 0

  vpc_id     = aws_vpc.this.id
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = local.vpc_id  # Uses local, not direct reference
  cidr_block = "10.1.0.0/24"
}

# On destroy:
# 1. Subnets deleted first (depend on local.vpc_id)
# 2. CIDR association deleted
# 3. VPC deleted last
```

### How try() Affects Dependencies

**Terraform's dependency graph:**

```
Without try():
aws_subnet → aws_vpc
aws_vpc_ipv4_cidr_block_association → aws_vpc

With try():
aws_subnet → local.vpc_id → aws_vpc_ipv4_cidr_block_association → aws_vpc
```

**Key insight:**
- `try()` lists resources in **priority order**
- Terraform sees **all resources in the try()** as dependencies
- This hints correct deletion order

### Other Use Cases

**NAT Gateway with optional EIP:**
```hcl
locals {
  nat_eip_id = try(
    aws_eip.nat[0].id,
    var.existing_eip_id,
    ""
  )
}
```

**ALB with optional WAF:**
```hcl
locals {
  alb_arn = try(
    aws_wafv2_web_acl_association.this[0].resource_arn,
    aws_lb.this.arn,
    ""
  )
}
```

---

## Modern Terraform Features (1.0+)

### Feature Availability

| Feature | Version | Use Case |
|---------|---------|----------|
| `try()` function | 0.13+ | Safe fallbacks, replaces `element(concat())` |
| `nullable = false` | 1.1+ | Prevent null values in variables |
| `moved` blocks | 1.1+ | Refactor without destroy/recreate |
| `optional()` with defaults | 1.3+ | Optional object attributes |
| Native testing | 1.6+ | Built-in test framework |
| Mock providers | 1.7+ | Cost-free unit testing |
| Provider functions | 1.8+ | Provider-specific data transformation |
| Cross-variable validation | 1.9+ | Validate relationships between variables |
| Write-only arguments | 1.11+ | Secrets never stored in state |

### try() - Safe Fallbacks (0.13+)

**Replaces old pattern:**
```hcl
# ❌ Old way (pre-0.13)
output "sg_id" {
  value = element(concat(aws_security_group.this.*.id, [""]), 0)
}

# ✅ Modern way
output "sg_id" {
  value = try(aws_security_group.this[0].id, "")
}
```

### optional() with Defaults (1.3+)

```hcl
variable "config" {
  type = object({
    name    = string
    timeout = optional(number, 300)  # Default: 300
    retries = optional(number, 3)    # Default: 3
    tags    = optional(map(string), {})
  })
}

# Usage
module "example" {
  source = "./module"

  config = {
    name = "my-app"
    # timeout and retries use defaults
    # tags uses default empty map
  }
}
```

### moved Blocks (1.1+)

**Refactor without recreation:**

```hcl
# Renamed resource
moved {
  from = aws_instance.server
  to   = aws_instance.web_server
}

# Moved to module
moved {
  from = aws_s3_bucket.logs
  to   = module.logging.aws_s3_bucket.logs
}

# Changed count to for_each
moved {
  from = aws_subnet.private[0]
  to   = aws_subnet.private["subnet_a"]
}
```

### Cross-Variable Validation (1.9+)

```hcl
variable "environment" {
  type = string
}

variable "backup_retention_days" {
  type    = number
  default = 7

  validation {
    condition     = var.environment == "prod" ? var.backup_retention_days >= 30 : true
    error_message = "Production environment requires backup_retention_days >= 30"
  }
}

variable "instance_type" {
  type = string

  validation {
    condition = (
      var.environment == "prod"
      ? contains(["t3.large", "t3.xlarge", "m5.large"], var.instance_type)
      : true
    )
    error_message = "Production must use t3.large or larger"
  }
}
```

### Write-Only Arguments (1.11+)

**Secrets that never appear in state:**

```hcl
resource "aws_db_instance" "this" {
  # Other arguments...

  password = var.db_password  # Never stored in state (if write-only)
}

# Provider defines which arguments are write-only
# Check provider documentation for support
```

---

## Version Management

### Version Constraint Syntax

```hcl
version = "5.0.0"      # Exact (avoid - inflexible)
version = "~> 5.0"     # Recommended: 5.0.x only (pessimistic)
version = ">= 5.0"     # Minimum (risky - breaking changes)
version = ">= 5.0, < 6.0"  # Range
```

**Pessimistic operator (`~>`):**
- `~> 5.0` → `>= 5.0, < 6.0` (allows 5.1, 5.2, etc.)
- `~> 5.1` → `>= 5.1, < 6.0`
- `~> 5.1.0` → `>= 5.1.0, < 5.2.0`

### Strategy by Component

| Component | Strategy | Example | Reasoning |
|-----------|----------|---------|-----------|
| **Terraform** | Pin minor version | `required_version = "~> 1.9"` | Balance stability and features |
| **Providers** | Pin major version | `version = "~> 5.0"` | Allow patches, avoid breaking changes |
| **Modules (prod)** | Pin exact version | `version = "5.1.2"` | Absolute stability |
| **Modules (dev)** | Allow patch updates | `version = "~> 5.1"` | Get bug fixes automatically |

### versions.tf Template

```hcl
terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

### Update Workflow

```bash
# 1. Lock versions initially
terraform init              # Creates .terraform.lock.hcl

# 2. Update to latest within constraints
terraform init -upgrade     # Updates providers

# 3. Review changes
cat .terraform.lock.hcl

# 4. Test
terraform plan

# 5. Commit lock file
git add .terraform.lock.hcl
git commit -m "Update provider versions"
```

### Terraform vs OpenTofu

Both tools support the same version syntax. Key differences:

| Feature | Terraform | OpenTofu |
|---------|-----------|----------|
| License | BSL 1.1 (post-1.6) | MPL 2.0 (open source) |
| Registry | registry.terraform.io | registry.opentofu.org |
| State encryption | Enterprise only | Built-in (1.7+) |
| Version syntax | Same | Same |

---

## Common Anti-Patterns to Avoid

### 1. Hardcoded Values

❌ **Bad:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  subnet_id     = "subnet-abcd1234"
}
```

✅ **Good:**
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
}
```

### 2. Not Using Terraform State

❌ **Bad:**
```bash
# Manual infrastructure changes
aws ec2 create-instance ...
```

✅ **Good:**
```bash
# Import existing resources
terraform import aws_instance.existing i-12345678
```

### 3. Mixing Environments in One State

❌ **Bad:**
```
terraform/
└── main.tf  # Contains both prod and dev
```

✅ **Good:**
```
environments/
├── prod/
│   └── main.tf
└── dev/
    └── main.tf
```

---

## File Organization Best Practices

### Standard Module Structure

```
my-module/
├── main.tf             # Primary resources
├── variables.tf        # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider versions
├── data.tf             # Data sources (optional)
├── locals.tf           # Local values (optional)
├── README.md           # Documentation
├── examples/
│   ├── minimal/        # Minimal working example
│   └── complete/       # Full-featured example
└── tests/
    └── module_test.tftest.hcl
```

### File Naming Conventions

| File | Purpose | When to Use |
|------|---------|-------------|
| `main.tf` | Primary resources | Always |
| `variables.tf` | Input variables | Always |
| `outputs.tf` | Output values | Always |
| `versions.tf` | Provider/Terraform versions | Always |
| `data.tf` | Data sources | When you have 3+ data sources |
| `locals.tf` | Local values | When you have many locals |
| `{resource}.tf` | Specific resource type | Large modules (e.g., `s3.tf`, `iam.tf`) |

### When to Split Files

**Keep in one file when:**
- Module is small (< 100 lines)
- Resources are tightly coupled

**Split into multiple files when:**
- Module > 200 lines
- Distinct logical groups (networking, compute, data)
- Easier to navigate and review

---

## Further Reading

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [AWS Terraform Modules](https://github.com/terraform-aws-modules)
