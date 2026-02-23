# Testing Frameworks Guide

Comprehensive guide to testing Terraform/OpenTofu code across different frameworks and approaches.

## Testing Pyramid for Infrastructure

```
        /\
       /  \          End-to-End Tests (Expensive)
      /____\         - Full environment deployment
     /      \        - Production-like setup
    /________\
   /          \      Integration Tests (Moderate)
  /____________\     - Module testing in isolation
 /              \    - Real resources in test account
/________________\   Static Analysis (Cheap)
                     - validate, fmt, lint
                     - Security scanning
```

## Decision Matrix: Which Testing Approach?

| Your Situation | Recommended Approach | Tools | Cost |
|----------------|---------------------|-------|------|
| **Quick syntax check** | Static analysis | `terraform validate`, `fmt` | Free |
| **Pre-commit validation** | Static + lint | `validate`, `tflint`, `trivy`, `checkov` | Free |
| **Terraform 1.6+, simple logic** | Native test framework | Built-in `terraform test` | Free-Low |
| **Pre-1.6, or Go expertise** | Integration testing | Terratest | Low-Med |
| **Security/compliance focus** | Policy as code | OPA, Sentinel | Free |
| **Cost-sensitive workflow** | Mock providers (1.7+) | Native tests + mocking | Free |
| **Multi-cloud, complex** | Full integration | Terratest + real infra | Med-High |

---

## 1. Static Analysis (Free, Fast)

### terraform validate

**What it checks:**
- Syntax errors
- Valid HCL structure
- Resource argument validity
- Type constraints

**Usage:**
```bash
terraform init
terraform validate
```

**Limitations:**
- Doesn't catch logical errors
- Doesn't verify actual resource behavior
- Requires valid provider configuration

---

### terraform fmt

**What it does:**
- Standardizes code formatting
- Ensures consistent style

**Usage:**
```bash
# Check formatting
terraform fmt -check -recursive

# Auto-fix formatting
terraform fmt -recursive
```

**Pre-commit integration:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
```

---

### tflint

**What it checks:**
- Deprecated syntax
- Unused declarations
- Provider-specific issues
- Best practice violations

**Installation:**
```bash
# Via mise (recommended)
mise use -g tflint@latest

# Via Homebrew
brew install tflint
```

**Configuration (.tflint.hcl):**
```hcl
plugin "aws" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_instance_invalid_type" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}
```

**Usage:**
```bash
tflint --init
tflint
```

---

## 2. Native Testing (Terraform 1.6+, OpenTofu 1.6+)

### Overview

Native testing provides built-in testing without external dependencies.

**Versions:**
- **1.6+**: Basic `terraform test` command
- **1.7+**: Mock providers for unit testing

### Test File Structure

```hcl
# tests/s3_bucket.tftest.hcl

# Optional: Specify Terraform version for tests
terraform {
  required_version = ">= 1.6.0"
}

# Test run with plan (fast, no resource creation)
run "validate_bucket_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "my-test-bucket"
    error_message = "Bucket name mismatch"
  }
}

# Test run with apply (creates real resources)
run "verify_encryption" {
  command = apply

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.this.rule) > 0
    error_message = "Bucket encryption not configured"
  }
}
```

### Command Modes

| Mode | When to Use | Resources Created | Cost |
|------|-------------|-------------------|------|
| `command = plan` | Input validation, fast checks | No | Free |
| `command = apply` | Verify computed values, set-type blocks | Yes | $ |

### Handling Set-Type Blocks

**Problem:**
```hcl
# This FAILS with command = plan
run "check_encryption" {
  command = plan

  assert {
    condition = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    #                                                                         ^^^ ERROR: Cannot index set
    error_message = "Expected AES256 encryption"
  }
}
```

**Solution 1: Use for expressions**
```hcl
run "check_encryption" {
  command = plan

  assert {
    condition = contains([
      for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule :
        rule.apply_server_side_encryption_by_default[0].sse_algorithm
    ], "AES256")
    error_message = "Expected AES256 encryption"
  }
}
```

**Solution 2: Use command = apply**
```hcl
run "check_encryption" {
  command = apply  # Materializes the set

  assert {
    condition = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Expected AES256 encryption"
  }
}
```

### Mock Providers (1.7+)

**Cost-free unit testing:**

```hcl
# tests/unit.tftest.hcl

mock_provider "aws" {}

run "unit_test_bucket_name" {
  command = plan

  variables {
    bucket_name = "test-bucket"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-bucket"
    error_message = "Bucket name not set correctly"
  }
}
```

### Running Tests

```bash
# Run all tests
terraform test

# Run specific test file
terraform test tests/s3_bucket.tftest.hcl

# Verbose output
terraform test -verbose

# JSON output for CI/CD
terraform test -json
```

---

## 3. Terratest (Go-based integration testing)

### When to Use Terratest

✅ **Use Terratest when:**
- You need complex integration tests
- Testing multi-cloud scenarios
- Custom validation logic required
- Using Terraform < 1.6

❌ **Don't use Terratest when:**
- Simple validation (use native tests)
- Cost is a concern (use mocks)
- Team lacks Go expertise

### Basic Structure

```go
// test/s3_bucket_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestS3Bucket(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/complete",
        Vars: map[string]interface{}{
            "bucket_name": "test-bucket-12345",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    bucketName := terraform.Output(t, terraformOptions, "bucket_name")
    assert.Equal(t, "test-bucket-12345", bucketName)
}
```

### Setup

```bash
# Initialize Go module
go mod init github.com/yourorg/yourmodule
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/stretchr/testify/assert

# Run tests
go test -v -timeout 30m
```

### Best Practices

1. **Use t.Parallel()** - Run tests concurrently
2. **Always defer Destroy** - Clean up resources
3. **Set timeouts** - Prevent hanging tests
4. **Tag resources** - Easy identification and cleanup
5. **Use unique names** - Prevent collisions

---

## 4. Security & Compliance Testing

### Trivy

**What it scans:**
- Misconfigurations
- Security vulnerabilities
- IaC issues

```bash
# Install
mise use -g trivy@latest

# Scan current directory
trivy config .

# Scan with severity threshold
trivy config --severity HIGH,CRITICAL .

# Output as table
trivy config --format table .
```

### Checkov

**What it checks:**
- 1000+ built-in policies
- CIS benchmarks
- GDPR, HIPAA, PCI-DSS compliance

```bash
# Install
pip install checkov

# Scan directory
checkov -d .

# Skip specific checks
checkov -d . --skip-check CKV_AWS_18

# Output as JSON
checkov -d . -o json
```

---

## 5. Policy as Code

### Open Policy Agent (OPA)

**Use case:** Custom compliance rules

```rego
# policy/s3_encryption.rego
package terraform.s3

deny[msg] {
    resource := input.resource.aws_s3_bucket[name]
    not resource.server_side_encryption_configuration
    msg := sprintf("S3 bucket '%s' missing encryption", [name])
}
```

**Testing policies:**
```bash
opa test policy/ -v
```

---

## Testing Strategy Recommendations

### For New Projects

```
1. Static Analysis (pre-commit)
   ├── terraform fmt -check
   ├── terraform validate
   ├── tflint
   └── trivy config

2. Unit Tests (PR validation)
   └── terraform test (with mocks, if 1.7+)

3. Integration Tests (main branch only)
   └── terraform test (real resources) or Terratest

4. Security Scan (scheduled)
   └── trivy + checkov
```

### Cost Optimization

| Stage | Frequency | Cost |
|-------|-----------|------|
| Static analysis | Every commit | Free |
| Mock tests | Every PR | Free |
| Integration tests | Main branch only | $$ |
| Full E2E | Release only | $$$ |

### CI/CD Integration

See [CI/CD Workflows Guide](ci-cd-workflows.md) for complete pipeline templates.

---

## Troubleshooting

### "Cannot index set" errors

**Cause:** Set-type blocks can't be indexed with `[0]` in plan mode

**Solutions:**
1. Use `for` expressions
2. Switch to `command = apply`
3. Check Terraform MCP for block types

### Terratest timeouts

**Cause:** Resources taking longer than expected

**Solutions:**
```go
terraformOptions := &terraform.Options{
    TerraformDir: "../examples/complete",
    RetryableTerraformErrors: map[string]string{
        ".*": "Retrying...",
    },
    MaxRetries: 3,
    TimeBetweenRetries: 5 * time.Second,
}
```

### Mock provider issues (1.7+)

**Problem:** Computed values return null

**Solution:** Use real providers for integration, mocks only for unit tests

---

## Further Reading

- [Terraform Testing Guide](https://developer.hashicorp.com/terraform/language/tests)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [tflint Rules](https://github.com/terraform-linters/tflint-ruleset-aws/blob/master/docs/rules/README.md)
