################################################################################
# Cluster
################################################################################

resource "aws_ecs_cluster" "this" {
  region = var.region
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

################################################################################
# CloudWatch Log Group
################################################################################

locals {
  log_group_name = try(coalesce(var.cloudwatch_log_group_name, "/aws/ecs/${var.name}"), "")
}

resource "aws_cloudwatch_log_group" "this" {
  region = var.region

  name              = local.log_group_name
  retention_in_days = var.cloudwatch_log_group_retention_in_days

  tags = merge(
    var.tags,
    var.cloudwatch_log_group_tags,
    { Name = local.log_group_name }
  )
}