# Quick Reference

Fast lookup guide for common Terraform/OpenTofu tasks, commands, and patterns.

---

## Command Cheat Sheet

### Essential Commands

| Command | Description | Common Flags |
|---------|-------------|--------------|
| `terraform init` | Initialize working directory | `-upgrade` (update providers) |
| `terraform validate` | Check configuration syntax | None commonly used |
| `terraform plan` | Show execution plan | `-out=FILE` (save plan) |
| `terraform apply` | Execute changes | `-auto-approve` (skip confirmation) |
| `terraform destroy` | Destroy infrastructure | `-auto-approve` |
| `terraform fmt` | Format code | `-recursive` (all subdirs) |
| `terraform output` | Show outputs | `-json` (JSON format) |
| `terraform state list` | List resources in state | None commonly used |
| `terraform state show` | Show resource details | `RESOURCE_ADDRESS` |
| `terraform test` | Run tests (1.6+) | `-verbose`, `-filter` |

### State Management

| Command | Description | Example |
|---------|-------------|---------|
| `terraform state mv` | Move resource | `terraform state mv aws_instance.old aws_instance.new` |
| `terraform state rm` | Remove from state | `terraform state rm aws_instance.old` |
| `terraform import` | Import existing resource | `terraform import aws_instance.new i-12345678` |
| `terraform state pull` | Download remote state | `terraform state pull > backup.tfstate` |
| `terraform state push` | Upload state | `terraform state push backup.tfstate` |
| `terraform force-unlock` | Unlock state | `terraform force-unlock LOCK_ID` |

### Workspace Management

| Command | Description |
|---------|-------------|
| `terraform workspace list` | List workspaces |
| `terraform workspace new NAME` | Create workspace |
| `terraform workspace select NAME` | Switch workspace |
| `terraform workspace show` | Show current workspace |
| `terraform workspace delete NAME` | Delete workspace |

---

## Common Patterns

### Resource Naming

```hcl
# ✅ Singleton resource
resource "aws_vpc" "this" {}

# ✅ Descriptive name for multiple resources
resource "aws_subnet" "private" {}
resource "aws_subnet" "public" {}

# ✅ Prefixed with context
resource "aws_instance" "web_server" {}
resource "aws_instance" "api_server" {}
```

### Variable Naming

```hcl
# ✅ Descriptive, prefixed with context
variable "vpc_cidr_block" {}
variable "database_instance_class" {}
variable "application_tags" {}

# ❌ Too generic
variable "cidr" {}
variable "instance_class" {}
variable "tags" {}
```

### File Organization

```
module/
├── main.tf           # Primary resources
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider versions
├── data.tf           # Data sources (optional)
└── locals.tf         # Local values (optional)
```

---

## Testing Approach Selection

### Decision Flowchart

```
Need to test Terraform code?
│
├─ Syntax/format check?
│  └─ Use: terraform fmt, terraform validate
│
├─ Security/compliance?
│  └─ Use: trivy, checkov
│
├─ Logic/behavior (Terraform 1.6+)?
│  ├─ No real resources needed?
│  │  └─ Use: terraform test (with mocks, if 1.7+)
│  └─ Need real resources?
│     └─ Use: terraform test (integration)
│
└─ Complex integration (pre-1.6 or Go)?
   └─ Use: Terratest
```

### Test Type Comparison

| Type | Speed | Cost | Use Case |
|------|-------|------|----------|
| Static (fmt, validate) | ⚡⚡⚡ | Free | Every commit |
| Mock tests (1.7+) | ⚡⚡ | Free | PR validation |
| Native integration | ⚡ | $ | Main branch |
| Terratest | ⚡ | $$ | Complex scenarios |

---

## Troubleshooting Guide

### Common Errors

#### "Error acquiring state lock"

**Cause:** Another operation is running or crashed

**Solution:**
```bash
# List locks
terraform force-unlock -force LOCK_ID

# Or wait for the lock to expire
```

#### "Error: Inconsistent dependency lock file"

**Cause:** `.terraform.lock.hcl` doesn't match providers

**Solution:**
```bash
terraform init -upgrade
```

#### "Error: Unsupported block type"

**Cause:** Using a block type that doesn't exist for that resource

**Solution:**
- Check provider documentation
- Use Terraform MCP to search schemas
- Verify provider version supports the block

#### "Cannot index set"

**Cause:** Trying to use `[0]` on a set-type block in `command = plan`

**Solution:**
```hcl
# Option 1: Use for expression
assert {
  condition = contains([
    for rule in aws_s3_bucket_lifecycle_configuration.this.rule :
      rule.id
  ], "expire-old-versions")
}

# Option 2: Use command = apply
run "test" {
  command = apply  # Materializes the set

  assert {
    condition = aws_s3_bucket_lifecycle_configuration.this.rule[0].id == "expire"
  }
}
```

#### "Error: Reference to undeclared resource"

**Cause:** Resource doesn't exist in configuration

**Solution:**
- Check spelling
- Verify resource is in scope
- Check if using wrong module path

#### "Error: Cycle in dependency graph"

**Cause:** Circular dependency between resources

**Solution:**
- Use `depends_on` carefully
- Break dependency cycle with data sources
- Restructure resource relationships

---

## Version-Specific Features

### Terraform/OpenTofu Version Matrix

| Version | Key Features |
|---------|--------------|
| **0.13** | `try()` function, `for_each` improvements |
| **1.0** | Stable release, production-ready |
| **1.1** | `nullable = false`, `moved` blocks |
| **1.3** | `optional()` with defaults |
| **1.6** | Native `terraform test` command |
| **1.7** | Mock providers for testing |
| **1.8** | Provider functions |
| **1.9** | Cross-variable validation |
| **1.11** | Write-only arguments |

### Choosing Terraform vs OpenTofu

| Aspect | Terraform | OpenTofu |
|--------|-----------|----------|
| **License** | BSL 1.1 (post-1.5) | MPL 2.0 (open source) |
| **Governance** | HashiCorp | Linux Foundation |
| **State encryption** | Enterprise only | Built-in (1.7+) |
| **Registry** | registry.terraform.io | registry.opentofu.org |
| **Feature parity** | Original | Fork from 1.5, diverging |
| **Commercial support** | HashiCorp Cloud Platform | Community + vendors |

**Recommendation:**
- **Use Terraform** if you need HCP features or enterprise support
- **Use OpenTofu** if you prefer open source or need built-in state encryption

---

## Functions Quick Reference

### Common Functions

| Function | Description | Example |
|----------|-------------|---------|
| `concat()` | Combine lists | `concat(["a"], ["b"])` → `["a", "b"]` |
| `merge()` | Combine maps | `merge({a=1}, {b=2})` → `{a=1, b=2}` |
| `try()` | Safe fallback | `try(var.x, "default")` |
| `can()` | Test if expression valid | `can(regex("^[a-z]+$", var.name))` |
| `lookup()` | Get map value | `lookup(var.map, "key", "default")` |
| `contains()` | Check if in list | `contains(["a", "b"], "a")` → `true` |
| `length()` | Get length | `length(["a", "b"])` → `2` |
| `keys()` | Get map keys | `keys({a=1, b=2})` → `["a", "b"]` |
| `values()` | Get map values | `values({a=1, b=2})` → `[1, 2]` |
| `cidrsubnet()` | Calculate subnet | `cidrsubnet("10.0.0.0/16", 8, 1)` → `"10.0.1.0/24"` |

### String Functions

| Function | Description | Example |
|----------|-------------|---------|
| `lower()` | Lowercase | `lower("ABC")` → `"abc"` |
| `upper()` | Uppercase | `upper("abc")` → `"ABC"` |
| `trimspace()` | Remove whitespace | `trimspace(" a ")` → `"a"` |
| `split()` | Split string | `split(",", "a,b,c")` → `["a", "b", "c"]` |
| `join()` | Join list | `join(",", ["a", "b"])` → `"a,b"` |
| `replace()` | Replace substring | `replace("hello", "l", "L")` → `"heLLo"` |
| `regex()` | Extract with regex | `regex("([0-9]+)", "abc123")` → `"123"` |

---

## Terraform vs OpenTofu Comparison

### CLI Commands

| Task | Terraform | OpenTofu |
|------|-----------|----------|
| Initialize | `terraform init` | `tofu init` |
| Plan | `terraform plan` | `tofu plan` |
| Apply | `terraform apply` | `tofu apply` |
| Test | `terraform test` | `tofu test` |

**Note:** Commands are identical, just different binary names.

### State Encryption

**Terraform:**
- Enterprise/Cloud only
- Requires HCP subscription

**OpenTofu (1.7+):**
```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "mykey" {
      passphrase = var.passphrase
    }

    state {
      enforced = true
      method "aes_gcm" "default" {
        keys = key_provider.pbkdf2.mykey
      }
    }
  }
}
```

### Migration Path

**Terraform → OpenTofu:**
```bash
# 1. Install OpenTofu
mise use -g opentofu@latest

# 2. Replace command
tofu init -migrate-state

# 3. Continue as normal
tofu plan
tofu apply
```

**OpenTofu → Terraform:**
```bash
# Remove OpenTofu-specific features first (e.g., encryption blocks)
terraform init -migrate-state
```

---

## Security Quick Checks

### Pre-commit Checklist

```bash
# 1. Format check
terraform fmt -check -recursive

# 2. Syntax validation
terraform validate

# 3. Security scan
trivy config --severity HIGH,CRITICAL .

# 4. Compliance check
checkov -d . --quiet --compact
```

### Common Security Fixes

| Issue | Fix |
|-------|-----|
| Unencrypted S3 | Add `aws_s3_bucket_server_side_encryption_configuration` |
| Public S3 | Add `aws_s3_bucket_public_access_block` |
| Open security group | Restrict `cidr_blocks` to specific IPs |
| Hardcoded secrets | Use AWS Secrets Manager or `random_password` |
| Unencrypted RDS | Set `storage_encrypted = true` |
| No logging | Add `aws_s3_bucket_logging` or CloudWatch logs |

---

## Import Existing Resources

### Common Import Patterns

```bash
# EC2 instance
terraform import aws_instance.example i-12345678

# S3 bucket
terraform import aws_s3_bucket.example my-bucket-name

# Security group
terraform import aws_security_group.example sg-12345678

# VPC
terraform import aws_vpc.example vpc-12345678

# IAM role
terraform import aws_iam_role.example role-name
```

### Import Workflow

```bash
# 1. Write resource block (without values)
cat > resource.tf <<EOF
resource "aws_instance" "imported" {
  # Configuration will be populated
}
EOF

# 2. Import
terraform import aws_instance.imported i-12345678

# 3. Generate configuration (1.5+)
terraform plan -generate-config-out=generated.tf

# 4. Review and merge
cat generated.tf >> resource.tf
rm generated.tf

# 5. Verify
terraform plan  # Should show no changes
```

---

## Useful One-Liners

### Find resources of specific type

```bash
terraform state list | grep aws_instance
```

### Get resource attributes

```bash
terraform state show aws_instance.example | grep "private_ip"
```

### Count resources by type

```bash
terraform state list | awk -F'.' '{print $1}' | sort | uniq -c
```

### Show all outputs as JSON

```bash
terraform output -json | jq
```

### Find unused variables

```bash
# List variables
grep "^variable" variables.tf | awk '{print $2}' | tr -d '"' > /tmp/vars.txt

# Find which are referenced
while read var; do
  grep -r "var.$var" *.tf || echo "Unused: $var"
done < /tmp/vars.txt
```

### Graph dependencies

```bash
terraform graph | dot -Tpng > graph.png
```

---

## CI/CD Quick Setup

### Minimal GitHub Actions

```yaml
# .github/workflows/terraform.yml
name: Terraform

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init -backend=false
      - run: terraform fmt -check
      - run: terraform validate
```

### Minimal GitLab CI

```yaml
# .gitlab-ci.yml
terraform:
  image: hashicorp/terraform:latest
  script:
    - terraform init -backend=false
    - terraform fmt -check
    - terraform validate
```

---

## Further Reading

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terraform Registry](https://registry.terraform.io/)
- [OpenTofu Registry](https://registry.opentofu.org/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
