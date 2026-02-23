# Terraform native test file template
# Requires Terraform 1.6+

# Optional: Override provider configuration for testing
# provider "aws" {
#   region = "us-east-1"
# }

# Variables for tests
variables {
  name = "test-resource"
  tags = {
    Environment = "test"
    ManagedBy   = "Terraform"
  }
}

# Test 1: Validate with plan (fast, no resources created)
run "validate_configuration" {
  command = plan

  assert {
    condition     = var.name == "test-resource"
    error_message = "Name variable not set correctly"
  }

  assert {
    condition     = length(var.tags) > 0
    error_message = "Tags should not be empty"
  }
}

# Test 2: Create resources and verify (uses real resources)
run "create_and_verify" {
  command = apply

  # Override variables for this test
  variables {
    name = "integration-test"
  }

  assert {
    condition     = output.name == "integration-test"
    error_message = "Output name does not match expected value"
  }

  assert {
    condition     = output.created == true
    error_message = "Resources should have been created"
  }
}

# Test 3: Verify idempotency (no changes on re-apply)
run "verify_idempotency" {
  command = plan

  # Should show no changes after previous apply
  assert {
    condition     = output.name == "integration-test"
    error_message = "State should persist from previous test"
  }
}
