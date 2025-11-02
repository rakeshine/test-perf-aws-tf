################################################################################
# Service
################################################################################

resource "aws_ecs_service" "this" {
  region = var.region
  launch_type  = "FARGATE"
  
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count

  network_configuration {
    subnets         = var.subnets
    security_groups = var.security_groups
  } 
  
  tags = var.tags
}