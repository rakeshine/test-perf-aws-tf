output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ecs_tasks.id
}