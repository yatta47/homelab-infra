# Output values

output "name" {
  description = "Name of the created resource"
  value       = var.name
}

output "created" {
  description = "Whether resources were created"
  value       = var.create
}
