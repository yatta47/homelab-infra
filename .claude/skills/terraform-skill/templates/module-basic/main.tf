# Main resource definitions
# Replace this with your actual resources

resource "null_resource" "example" {
  count = var.create ? 1 : 0

  triggers = {
    name = var.name
  }
}
