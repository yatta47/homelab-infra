# Terraform Code Review Checklist

Use this checklist when reviewing Terraform/OpenTofu code to ensure best practices and security.

---

## 📋 Structure & Organization

### Files

- [ ] Standard files present: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- [ ] Files are appropriately sized (< 200 lines for `main.tf`)
- [ ] Large modules split by resource type (`s3.tf`, `iam.tf`, etc.)
- [ ] `examples/` directory with working examples
- [ ] `tests/` directory with test files

### Directories

- [ ] Modules separated from environments
- [ ] Clear module hierarchy (resource → infrastructure → composition)
- [ ] No duplicate code across environments

---

## 🏷️ Naming Conventions

### Resources

- [ ] Singleton resources use `"this"` name
- [ ] Multiple resources use descriptive names
- [ ] No generic names (`main`, `resource`, `item`)
- [ ] Consistent naming style (snake_case)

### Variables

- [ ] Descriptive names with context (`vpc_cidr_block` not `cidr`)
- [ ] Plural for lists (`subnet_ids` not `subnet_id`)
- [ ] No abbreviations unless standard (`az` → `availability_zones`)

### Files

- [ ] `main.tf` for primary resources
- [ ] `data.tf` only if 3+ data sources
- [ ] `locals.tf` only if many locals
- [ ] Logical file splits when needed

---

## 📝 Block Ordering

### Resource Blocks

- [ ] `count`/`for_each` FIRST (with blank line after)
- [ ] Other arguments (alphabetical recommended)
- [ ] `tags` as last real argument
- [ ] `depends_on` after tags (if needed)
- [ ] `lifecycle` at the very end (if needed)

### Variable Blocks

- [ ] `description` first (ALWAYS required)
- [ ] `type` second
- [ ] `default` third
- [ ] `validation` fourth
- [ ] `nullable` last (when false)

### Output Blocks

- [ ] `description` first (ALWAYS required)
- [ ] `value` second
- [ ] `sensitive` last (if true)

---

## 🔧 Code Quality

### Count vs For_Each

- [ ] `count` used for boolean conditions (`count = var.create ? 1 : 0`)
- [ ] `for_each` used for lists/maps that may change
- [ ] No `count` for lists that may be reordered

### Variables

- [ ] All variables have `description`
- [ ] Explicit `type` constraints
- [ ] Sensible `default` values where appropriate
- [ ] `validation` blocks for complex constraints
- [ ] `sensitive = true` for secrets
- [ ] `nullable = false` where null is invalid

### Outputs

- [ ] All outputs have `description`
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] Only output what consumers need
- [ ] No redundant outputs

### Locals

- [ ] Used for dependency management (try() pattern)
- [ ] Used to reduce repetition
- [ ] Not overused (max 20-30 locals)

---

## 🔒 Security

### Encryption

- [ ] S3 buckets have encryption enabled
- [ ] EBS volumes encrypted
- [ ] RDS/Aurora encrypted
- [ ] Secrets in Secrets Manager (not hardcoded)
- [ ] TLS/HTTPS for data in transit

### Network Security

- [ ] Security groups follow least privilege
- [ ] No `0.0.0.0/0` ingress (except HTTP/HTTPS for public services)
- [ ] Private subnets for databases/internal services
- [ ] VPC Flow Logs enabled

### Access Control

- [ ] IAM roles follow least privilege
- [ ] No hardcoded credentials
- [ ] Service accounts for automation

### Logging

- [ ] CloudTrail enabled
- [ ] VPC Flow Logs enabled
- [ ] S3 access logging enabled
- [ ] CloudWatch logs configured

### Public Access

- [ ] No unnecessary public IPs
- [ ] S3 buckets have public access blocked
- [ ] Load balancers used instead of direct public access

---

## 🧪 Testing

### Test Coverage

- [ ] Static analysis runs (fmt, validate, lint)
- [ ] Security scans (Trivy, Checkov)
- [ ] Unit tests with mocks (1.7+)
- [ ] Integration tests on main branch

### Test Files

- [ ] Tests in `tests/*.tftest.hcl`
- [ ] Use `command = plan` for fast validation
- [ ] Use `command = apply` for computed values
- [ ] Handle set-type blocks correctly

---

## 📦 Module Design

### Interface

- [ ] Simple, focused purpose
- [ ] Minimal required variables
- [ ] Sensible defaults
- [ ] Clear outputs

### Dependencies

- [ ] Explicit provider versions
- [ ] Terraform version constraint
- [ ] Module versions pinned in production

### Documentation

- [ ] README with usage examples
- [ ] Input/output tables
- [ ] Requirements listed
- [ ] Examples provided

---

## 🔄 CI/CD

### Automation

- [ ] Pre-commit hooks configured
- [ ] Automated validation on PR
- [ ] Plan on PR with comment
- [ ] Apply requires approval (production)

### State Management

- [ ] Remote state configured
- [ ] State locking enabled (DynamoDB)
- [ ] State encrypted
- [ ] Separate state per environment

### Cost Control

- [ ] Mock tests on every PR
- [ ] Integration tests only on main
- [ ] Auto-cleanup configured
- [ ] Test resources tagged

---

## 🔍 Common Issues

### Anti-Patterns

- [ ] No hardcoded values (AMIs, IPs, etc.)
- [ ] No secrets in code
- [ ] No mixing environments in one state
- [ ] No skipping state locking
- [ ] No `terraform apply -auto-approve` in production

### Potential Bugs

- [ ] Proper dependency management (implicit + explicit)
- [ ] No circular dependencies
- [ ] Correct use of `try()` for deletion order
- [ ] Set-type blocks handled correctly in tests

### Performance

- [ ] Parallel resource creation where possible
- [ ] No unnecessary data source lookups
- [ ] Efficient use of `for_each` vs `count`

---

## ✅ Version-Specific Features

### Modern Features Used (1.6+)

- [ ] Native testing (`terraform test`)
- [ ] Mock providers (1.7+) for unit tests
- [ ] `optional()` with defaults (1.3+)
- [ ] Cross-variable validation (1.9+)
- [ ] `moved` blocks for refactoring (1.1+)

### Deprecated Patterns Avoided

- [ ] No `element(concat())` → use `try()`
- [ ] No `-target` in production
- [ ] No outdated functions

---

## 📊 Scan Results

### Trivy

```bash
trivy config --severity HIGH,CRITICAL .
```

- [ ] No HIGH or CRITICAL issues
- [ ] Acknowledged issues have suppressions with reasons

### Checkov

```bash
checkov -d . --compact
```

- [ ] No policy violations
- [ ] Skipped checks documented in `.checkov.yml`

### TFLint

```bash
tflint
```

- [ ] No warnings or errors
- [ ] Provider-specific rules enabled

---

## 📝 Notes

Use this section to document review findings, decisions, or follow-up items:

```
-
-
-
```

---

## Final Verdict

- [ ] ✅ **APPROVED** - Ready to merge
- [ ] ⚠️ **APPROVED WITH COMMENTS** - Merge after addressing comments
- [ ] ❌ **CHANGES REQUESTED** - Requires fixes before merge

---

**Reviewer:** _____________
**Date:** _____________
**PR:** #_____________
