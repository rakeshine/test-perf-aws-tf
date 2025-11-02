################################################################################
# Service
################################################################################

output "id" {
  description = "ARN that identifies the service"
  value       = aws_ecs_service.this.id
}

output "name" {
  description = "Name of the service"
  value       = aws_ecs_service.this.name
}