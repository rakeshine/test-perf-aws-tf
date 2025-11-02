################################################################################
# Task Definition Outputs
################################################################################n
output "master_task_definition_arn" {
  description = "ARN of the master task definition"
  value       = var.master_required ? aws_ecs_task_definition.master[0].arn : null
}

output "slave_task_definition_arns" {
  description = "List of ARNs of the slave task definitions"
  value       = var.slaves_count > 0 ? [aws_ecs_task_definition.slave[0].arn] : []
}

output "master_task_definition_family" {
  description = "Family of the master task definition"
  value       = var.master_required ? aws_ecs_task_definition.master[0].family : null
}

output "slave_task_definition_families" {
  description = "List of family names of the slave task definitions"
  value       = var.slaves_count > 0 ? [aws_ecs_task_definition.slave[0].family] : []
}

output "task_execution_role_arn" {
  description = "The ARN of the task execution role that was used"
  value       = var.ecs_task_exec_role_arn
}

output "task_role_arn" {
  description = "The ARN of the task role that was used"
  value       = var.ecs_task_role_arn != null ? var.ecs_task_role_arn : var.ecs_task_exec_role_arn
}
