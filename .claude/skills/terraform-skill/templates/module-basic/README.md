# Module Name

Brief description of what this module does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Usage

### Minimal Example

```hcl
module "example" {
  source = "./path/to/module"

  name = "my-resource"
}
```

### Complete Example

See [examples/complete](examples/complete/) for full configuration.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |

## Providers

| Name | Version |
|------|---------|
| (Add your providers here) | |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | `string` | n/a | yes |
| create | Whether to create resources | `bool` | `true` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | Name of the created resource |
| created | Whether resources were created |

## Examples

- [Minimal](examples/minimal/) - Basic usage with defaults
- [Complete](examples/complete/) - All features enabled

## Testing

```bash
# Run all tests
terraform test

# Run specific test
terraform test tests/module.tftest.hcl
```

## License

Apache 2.0
