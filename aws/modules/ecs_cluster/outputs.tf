################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = try(aws_ecs_cluster.this.arn, null)
}

output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = try(aws_ecs_cluster.this.id, null)
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = try(aws_ecs_cluster.this.name, null)
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this.name, null)
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this.arn, null)
}