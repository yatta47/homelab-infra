# Security & Compliance Guide

Comprehensive security best practices and compliance testing for Terraform/OpenTofu infrastructure.

---

## Security Scanning Tools

### Trivy

**What it scans:**
- Misconfigurations
- Security vulnerabilities
- IaC issues
- Compliance violations

#### Installation

```bash
# Via mise (recommended)
mise use -g trivy@latest

# Via Homebrew
brew install trivy

# Via Docker
docker pull aquasec/trivy:latest
```

#### Basic Usage

```bash
# Scan current directory
trivy config .

# Scan with severity threshold
trivy config --severity HIGH,CRITICAL .

# Output formats
trivy config --format table .
trivy config --format json . > results.json
trivy config --format sarif . > results.sarif

# Scan specific directory
trivy config ./environments/prod

# Exit with error on findings
trivy config --exit-code 1 .
```

#### Common Issues Detected

```terraform
# ❌ Unencrypted S3 bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
  # Missing encryption configuration
}

# Trivy: AVD-AWS-0088 (HIGH)
# S3 Bucket does not have encryption enabled

# ✅ Fixed
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
```

---

### Checkov

**What it checks:**
- 1000+ built-in policies
- CIS benchmarks
- GDPR, HIPAA, PCI-DSS compliance
- Custom policies

#### Installation

```bash
# Via pip
pip install checkov

# Via Homebrew
brew install checkov

# Via Docker
docker pull bridgecrew/checkov:latest
```

#### Basic Usage

```bash
# Scan current directory
checkov -d .

# Scan specific framework
checkov -d . --framework terraform

# Skip specific checks
checkov -d . --skip-check CKV_AWS_18,CKV_AWS_19

# Output formats
checkov -d . -o json
checkov -d . -o sarif

# Compact output
checkov -d . --compact

# Fail on specific severity
checkov -d . --check HIGH,CRITICAL
```

#### Configuration File

```yaml
# .checkov.yml
framework:
  - terraform

skip-check:
  - CKV_AWS_18  # S3 bucket logging
  - CKV_AWS_21  # S3 bucket versioning

quiet: true
compact: true
```

#### Common Checks

| Check ID | Description | Severity |
|----------|-------------|----------|
| CKV_AWS_18 | S3 bucket logging | LOW |
| CKV_AWS_19 | S3 bucket encryption | HIGH |
| CKV_AWS_20 | S3 bucket public access | CRITICAL |
| CKV_AWS_23 | Security group unrestricted ingress | HIGH |
| CKV_AWS_24 | Security group unrestricted egress | MEDIUM |
| CKV_AWS_33 | KMS key rotation | MEDIUM |
| CKV_AWS_40 | IAM password policy | HIGH |

---

### tfsec (Legacy - Migrated to Trivy)

**Note:** tfsec has been archived and migrated to Trivy. Use `trivy config` instead.

---

## Common Security Issues & Fixes

### 1. Unencrypted Storage

#### S3 Buckets

❌ **Insecure:**
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}
```

✅ **Secure:**
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
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

#### EBS Volumes

❌ **Insecure:**
```hcl
resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 100
}
```

✅ **Secure:**
```hcl
resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn
}
```

#### RDS Databases

❌ **Insecure:**
```hcl
resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.t3.micro"
  # storage_encrypted not set
}
```

✅ **Secure:**
```hcl
resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.t3.micro"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
}
```

---

### 2. Overly Permissive Security Groups

❌ **Insecure:**
```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world!
  }
}
```

✅ **Secure:**
```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  # Only allow HTTP/HTTPS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # OK for public web traffic
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # OK for public web traffic
  }

  # Restrict egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]  # VPC only
  }
}
```

---

### 3. Secrets in Code

❌ **Insecure:**
```hcl
resource "aws_db_instance" "main" {
  username = "admin"
  password = "SuperSecret123!"  # Hardcoded!
}
```

✅ **Secure (Secrets Manager):**
```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "prod/database/password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password  # Passed via environment variable
}

resource "aws_db_instance" "main" {
  username = "admin"
  password = aws_secretsmanager_secret_version.db_password.secret_string
}
```

✅ **Secure (Random Password):**
```hcl
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_db_instance" "main" {
  username = "admin"
  password = random_password.db_password.result
}

# Store in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

output "db_password_secret_arn" {
  value     = aws_secretsmanager_secret.db_password.arn
  sensitive = true
}
```

---

### 4. Public Resources

❌ **Insecure:**
```hcl
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true  # Directly exposed
  subnet_id                   = aws_subnet.public.id
}
```

✅ **Secure:**
```hcl
# Use load balancer instead
resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id  # Private subnet
  # No public IP
}
```

---

### 5. Missing Logging

❌ **Insecure:**
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
  # No logging
}
```

✅ **Secure:**
```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "my-logs-bucket"
}

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

resource "aws_s3_bucket_logging" "data" {
  bucket = aws_s3_bucket.data.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}
```

---

## State File Security

### Problem: Sensitive Data in State

Terraform state files contain:
- Resource IDs
- IP addresses
- Secrets (passwords, keys)
- Configuration details

### Solutions

#### 1. Encrypt State at Rest

**S3 Backend:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # Server-side encryption
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    dynamodb_table = "terraform-locks"
  }
}
```

**OpenTofu Native Encryption (1.7+):**
```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "mykey" {
      passphrase = var.encryption_passphrase
    }

    state {
      enforced = true
      method "aes_gcm" "mymethod" {
        keys = key_provider.pbkdf2.mykey
      }
    }

    plan {
      enforced = true
      method "aes_gcm" "mymethod" {
        keys = key_provider.pbkdf2.mykey
      }
    }
  }
}
```

#### 2. Restrict State Access

**S3 Bucket Policy:**
```hcl
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::123456789012:role/TerraformRole"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}
```

#### 3. Enable Versioning

```hcl
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

#### 4. Use Write-Only Arguments (1.11+)

```hcl
# Password never stored in state (if provider supports it)
resource "aws_db_instance" "this" {
  password = var.db_password  # Write-only
}
```

---

## Compliance Testing

### CIS Benchmarks

```bash
# Check against CIS AWS Foundations Benchmark
checkov -d . --framework terraform --check CIS_AWS

# Specific CIS checks
checkov -d . --check CIS_AWS_1.1  # Password policy
checkov -d . --check CIS_AWS_2.1  # CloudTrail enabled
checkov -d . --check CIS_AWS_4.1  # Monitoring configuration
```

### GDPR Compliance

```bash
# GDPR-specific checks
checkov -d . --framework terraform | grep GDPR
```

**Key GDPR requirements:**
- Data encryption (at rest and in transit)
- Data retention policies
- Access logging
- Data residency (region constraints)

**Example:**
```hcl
# Enforce EU region
variable "aws_region" {
  type = string

  validation {
    condition     = contains(["eu-west-1", "eu-central-1"], var.aws_region)
    error_message = "GDPR compliance requires EU region"
  }
}

# Data retention
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "gdpr-retention"
    status = "Enabled"

    expiration {
      days = 2555  # 7 years
    }
  }
}
```

### HIPAA Compliance

**Requirements:**
- Encryption at rest and in transit
- Access controls and logging
- Audit trails
- Data backup

```hcl
# HIPAA-compliant RDS
resource "aws_db_instance" "hipaa" {
  engine               = "postgres"
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.hipaa.arn

  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Backup
  backup_retention_period = 35  # HIPAA recommends 30+ days

  # High availability
  multi_az = true

  # Deletion protection
  deletion_protection = true
}
```

---

## Policy as Code

### Open Policy Agent (OPA)

**Installation:**
```bash
mise use -g opa@latest
```

**Example Policy:**
```rego
# policy/s3_encryption.rego
package terraform.s3

import future.keywords.if
import future.keywords.contains

deny[msg] if {
    resource := input.resource.aws_s3_bucket[name]
    not has_encryption(name)
    msg := sprintf("S3 bucket '%s' must have encryption enabled", [name])
}

has_encryption(name) if {
    input.resource.aws_s3_bucket_server_side_encryption_configuration[name]
}
```

**Testing Policies:**
```bash
# Convert Terraform to JSON
terraform show -json tfplan > tfplan.json

# Test policy
opa eval -i tfplan.json -d policy/ "data.terraform.s3.deny"
```

---

## Best Practices Checklist

### ✅ Encryption

- [ ] S3 buckets encrypted (KMS preferred)
- [ ] EBS volumes encrypted
- [ ] RDS/Aurora encrypted
- [ ] Secrets Manager for secrets
- [ ] TLS/HTTPS for data in transit

### ✅ Network Security

- [ ] Security groups follow least privilege
- [ ] No 0.0.0.0/0 ingress (except HTTP/HTTPS for public services)
- [ ] Private subnets for databases/internal services
- [ ] NACLs configured
- [ ] VPC Flow Logs enabled

### ✅ Access Control

- [ ] IAM roles follow least privilege
- [ ] MFA enforced for sensitive operations
- [ ] No hardcoded credentials
- [ ] Service accounts for automation

### ✅ Logging & Monitoring

- [ ] CloudTrail enabled
- [ ] VPC Flow Logs enabled
- [ ] S3 access logging enabled
- [ ] CloudWatch alarms configured

### ✅ Compliance

- [ ] Scan with Trivy/Checkov in CI/CD
- [ ] Regular security audits
- [ ] Compliance framework checks (CIS, GDPR, HIPAA)
- [ ] State file encrypted and access-controlled

---

## CI/CD Integration

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_trivy
        args:
          - --args=--severity=HIGH,CRITICAL
      - id: terraform_checkov
        args:
          - --args=--quiet
```

### GitHub Actions

```yaml
- name: Security Scan
  run: |
    trivy config --severity HIGH,CRITICAL --exit-code 1 .
    checkov -d . --compact --quiet
```

---

## Further Reading

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/terraform.html)
- [CIS AWS Benchmarks](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [OWASP Infrastructure as Code Security](https://owasp.org/www-project-devsecops-guideline/)
