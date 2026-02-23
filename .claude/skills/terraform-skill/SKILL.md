---
name: terraform-skill
description: "Interactive Terraform/OpenTofu best practices assistant with code review and generation"
license: Apache-2.0
metadata:
  author: "Anton Babenko (adapted for Claude Code)"
  version: 2.0.0
  source: "https://github.com/antonbabenko/terraform-skill"
  risk: safe
triggers:
  keywords: ["terraform", "tofu", "opentofu", "tf", "hcl"]
  file_patterns: ["*.tf", "*.tfvars", "*.tftest.hcl"]
  commands: ["/terraform", "/tf-review", "/tf-init", "/tf-test", "/tf-security"]
---

# Terraform Skill for Claude Code

Interactive assistant for Terraform/OpenTofu best practices, code review, module generation, and testing.

---

## 🚀 Quick Start

**What do you need?**

- 🆕 **New module** → Use `/tf-init` to scaffold
- 🔍 **Code review** → Show me your .tf files or use `/tf-review`
- 🧪 **Add tests** → Use `/tf-test` for test templates
- 🔒 **Security check** → Use `/tf-security` for scan commands
- 📚 **Learn** → Ask about specific patterns or best practices

---

## 🎯 Core Principles

### 1. Progressive Disclosure
Essential info here, detailed guides available on demand:
- [Testing Frameworks](references/testing-frameworks.md)
- [Module Patterns](references/module-patterns.md)
- [CI/CD Workflows](references/ci-cd-workflows.md)
- [Security & Compliance](references/security-compliance.md)
- [Code Patterns](references/code-patterns.md)
- [Quick Reference](references/quick-reference.md)

### 2. Module Hierarchy
```
Composition (environments/prod/)
└── Infrastructure Module
    └── Resource Modules (VPC, RDS, ECS, etc.)
```

**Golden Rule:** Keep modules small, focused, and single-purpose.

### 3. Essential Standards

**Resource Naming:**
- Singleton: `resource "aws_vpc" "this" {}`
- Multiple: `resource "aws_subnet" "public" {}`, `"private" {}`

**Block Ordering (Strict):**
1. `count`/`for_each` FIRST (blank line after)
2. Other arguments
3. `tags` last
4. `depends_on` (if needed)
5. `lifecycle` (if needed)

**Variables Must Have:**
- `description` (always)
- `type` (explicit)
- `default` (where appropriate)
- `validation` (for complex constraints)

---

## 🤖 Interactive Features

### Auto Code Review

When you show me `.tf` files, I automatically check:

✅ **Structure**
- File organization
- Module hierarchy
- Naming conventions

✅ **Code Quality**
- Block ordering
- Variable/output completeness
- Count vs for_each usage

✅ **Security**
- Encryption settings
- Security group rules
- Hardcoded secrets
- Public access

✅ **Modern Features**
- Version-appropriate functions
- Testing approach
- State management

### Commands

#### `/tf-init` - Create Module Scaffold

Generates a complete module structure:
```
my-module/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── tests/
    └── module.tftest.hcl
```

**Usage:**
```
/tf-init module-name aws
```

#### `/tf-review` - Comprehensive Code Review

Runs a thorough review checklist covering:
- Structure & organization
- Naming conventions
- Block ordering
- Security issues
- Testing coverage
- CI/CD readiness

Returns a detailed report with specific recommendations.

#### `/tf-test` - Generate Test Templates

Creates test files based on your Terraform version:
- **1.6+**: Native `terraform test` files
- **1.7+**: Includes mock provider examples
- **Pre-1.6**: Terratest Go templates

**Usage:**
```
/tf-test
```

#### `/tf-security` - Security Scan Guide

Provides commands and configuration for:
- Trivy scanning
- Checkov compliance checks
- Pre-commit hooks
- CI/CD security integration

---

## 📊 Testing Strategy

### Quick Decision Matrix

| Your Situation | Use | Cost |
|----------------|-----|------|
| Syntax check | `terraform validate` | Free |
| Pre-commit | `tflint` + `trivy` | Free |
| Terraform 1.6+ | Native `terraform test` | Free-Low |
| Cost-sensitive | Mocks (1.7+) | Free |
| Complex integration | Terratest | Med-High |

### Testing Pyramid

```
     /\       End-to-End (Expensive)
    /  \      - Full environment
   /____\     - Production-like
  /      \    Integration (Moderate)
 /________\   - Module testing
/          \  Static Analysis (Cheap)
/___________\ - validate, fmt, lint
```

**Best Practice:**
1. **Every commit**: fmt, validate, lint (free)
2. **Every PR**: Mock tests (free)
3. **Main branch**: Integration tests (controlled cost)
4. **Release**: Full E2E (expensive)

See [Testing Frameworks Guide](references/testing-frameworks.md) for detailed strategies.

---

## 🔒 Security Quick Checks

### Essential Commands

```bash
# Format and validate
terraform fmt -check -recursive
terraform validate

# Security scanning
trivy config --severity HIGH,CRITICAL .
checkov -d . --compact

# Linting
tflint --init
tflint
```

### Common Issues to Fix

| Issue | Fix |
|-------|-----|
| Unencrypted S3 | Add `aws_s3_bucket_server_side_encryption_configuration` |
| Public S3 | Add `aws_s3_bucket_public_access_block` |
| Open security group | Restrict `cidr_blocks` |
| Hardcoded secrets | Use Secrets Manager or `random_password` |
| Unencrypted RDS | Set `storage_encrypted = true` |

See [Security & Compliance Guide](references/security-compliance.md) for comprehensive security practices.

---

## 🎨 Code Patterns

### Count vs For_Each

**Use `count` for:**
- Boolean conditions: `count = var.create ? 1 : 0`
- Fixed number of identical resources

**Use `for_each` for:**
- Lists that may be reordered
- Maps for named access
- Stable resource addressing

**Example:**
```hcl
# ✅ Boolean condition
resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0
  # ...
}

# ✅ Stable addressing
resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)
  availability_zone = each.key
  # ...
}
```

### Modern Features (1.6+)

```hcl
# try() - Safe fallbacks (0.13+)
output "sg_id" {
  value = try(aws_security_group.this[0].id, "")
}

# optional() - Optional attributes with defaults (1.3+)
variable "config" {
  type = object({
    name    = string
    timeout = optional(number, 300)  # Default: 300
  })
}

# Cross-variable validation (1.9+)
variable "backup_days" {
  type = number
  validation {
    condition     = var.environment == "prod" ? var.backup_days >= 7 : true
    error_message = "Production requires backup_days >= 7"
  }
}
```

See [Code Patterns Guide](references/code-patterns.md) for comprehensive patterns.

---

## 🔧 Templates & Tools

### Available Templates

📁 **Module Scaffold** ([templates/module-basic/](templates/module-basic/))
- Standard module structure
- Pre-configured files
- README template

📄 **Test Template** ([templates/test-native.tftest.hcl](templates/test-native.tftest.hcl))
- Native testing examples
- Plan and apply tests
- Assertion patterns

📄 **Version Template** ([templates/versions.tf.template](templates/versions.tf.template))
- Provider version constraints
- Backend configuration
- Common providers

### Tools

✅ **Review Checklist** ([tools/review-checklist.md](tools/review-checklist.md))
- Comprehensive code review guide
- Security checklist
- CI/CD readiness

---

## 📚 Detailed Guides

When you need in-depth information:

| Guide | What's Inside |
|-------|---------------|
| **[Testing Frameworks](references/testing-frameworks.md)** | Static analysis, native tests, Terratest, security scanning, cost optimization |
| **[Module Patterns](references/module-patterns.md)** | Module structure, variable/output design, DO vs DON'T patterns, versioning |
| **[CI/CD Workflows](references/ci-cd-workflows.md)** | GitHub Actions, GitLab CI, Atlantis, cost optimization, drift detection |
| **[Security & Compliance](references/security-compliance.md)** | Trivy/Checkov, secrets management, state security, CIS/GDPR/HIPAA |
| **[Code Patterns](references/code-patterns.md)** | Count vs for_each, locals, modern features, anti-patterns, file organization |
| **[Quick Reference](references/quick-reference.md)** | Command cheat sheet, troubleshooting, one-liners, version matrix |

---

## 🎯 When to Use This Skill

**✅ Activate for:**
- Creating Terraform/OpenTofu configurations or modules
- Code reviews and refactoring
- Setting up testing infrastructure
- Security and compliance checks
- CI/CD integration
- Multi-environment deployments
- Troubleshooting Terraform issues

**❌ Don't activate for:**
- Basic syntax questions (Claude knows this already)
- Provider-specific API reference (link to docs instead)
- Cloud platform questions unrelated to IaC

---

## 🔄 Terraform vs OpenTofu

Both fully supported. Key differences:

| Aspect | Terraform | OpenTofu |
|--------|-----------|----------|
| License | BSL 1.1 (post-1.5) | MPL 2.0 (open source) |
| State encryption | Enterprise only | Built-in (1.7+) |
| Governance | HashiCorp | Linux Foundation |
| Commands | `terraform` | `tofu` (otherwise identical) |

**Migration:** Simple command swap - state is compatible.

See [Quick Reference: Terraform vs OpenTofu](references/quick-reference.md#terraform-vs-opentofu-comparison) for details.

---

## 📖 Usage Examples

### Example 1: Quick Code Review

**You:**
```
Review this S3 bucket configuration:

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}
```

**Claude:**
```
⚠️ Security Issues Found:

1. Missing encryption configuration
2. No public access block
3. No versioning enabled

✅ Recommended fixes:

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Example 2: Generate Module

**You:**
```
/tf-init vpc-module aws
```

**Claude:**
Creates complete module structure with:
- Standard files (main.tf, variables.tf, outputs.tf, versions.tf)
- README with usage examples
- Test template
- AWS provider configuration

### Example 3: Testing Advice

**You:**
```
How should I test this module? I'm using Terraform 1.7.
```

**Claude:**
```
✅ Recommended approach for Terraform 1.7:

1. **Unit tests (free):**
   Use mock providers - no real resources

2. **Integration tests (controlled cost):**
   Run only on main branch with real resources

3. **CI/CD setup:**
   - Pre-commit: fmt, validate, tflint
   - PR: mock tests + plan
   - Main branch: integration tests
   - Auto-cleanup: prevent orphaned resources

I'll generate a test template for you...
```

---

## 📄 License

This skill is licensed under the **Apache License 2.0**.

**Copyright © 2026 Anton Babenko**
Adapted for Claude Code with interactive features and enhanced guidance.

---

## 🆘 Getting Help

**Within Claude Code:**
- Ask specific questions about patterns
- Show me your code for review
- Use `/tf-review` for comprehensive analysis

**For issues with this skill:**
- Report at skill source repository
- Check [Quick Reference](references/quick-reference.md) for troubleshooting

**For Terraform/OpenTofu help:**
- [Terraform Documentation](https://developer.hashicorp.com/terraform)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
