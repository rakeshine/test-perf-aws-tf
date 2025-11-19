################################################################################
# Task Definitions
################################################################################

locals {
  name_prefix = var.name
  
  # Common container definitions
  master_container_definition = {
    name         = "jmeter-master"
    image        = var.ecr_image
    essential    = true
    #entryPoint   = ["/bin/sh", "-c"]
    #command      = ["./run-master.sh"]
    portMappings = var.master_port_mappings
    environment  = concat(
      [
        { name = "SERVER_PORT", value = tostring(var.server_port) },
        { name = "SERVER_RMI_LOCALPORT", value = tostring(var.server_rmi_localport) },
        { name = "JMETER_MODE", value = "master" },
        { name = "JMETER_SLAVE_HOSTS", value = "" },
        { name = "TEST_PLAN_S3", value = "s3://test-surge-perf/test" },
        { name = "RESULT_S3", value = "s3://test-surge-perf/test/results/result.jtl" }
      ],
      var.environment_variables
    )
    logConfiguration = {
      logDriver = "awslogs"
      options   = {
        "awslogs-group"         = "${local.name_prefix}-jmeter-master"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "master"
      }
    }
  }

  slave_container_definition = {
    name         = "jmeter-slave"
    image        = var.ecr_image
    essential    = true
    #entryPoint   = ["/bin/sh", "-c"]
    #command      = ["./run-slave.sh"]
    portMappings = var.slave_port_mappings
    environment  = concat(
      [
        { name = "JMETER_MODE", value = "slave" },
        { name = "SERVER_PORT", value = tostring(var.server_port) },
        { name = "SERVER_RMI_LOCALPORT", value = tostring(var.server_rmi_localport) }
      ],
      var.environment_variables
    )
    logConfiguration = {
      logDriver = "awslogs"
      options   = {
        "awslogs-group"         = "${local.name_prefix}-jmeter-slave"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "slave"
      }
    }
  }
}

# Master Task Definitions
resource "aws_ecs_task_definition" "master" {
  count                    = var.master_required ? 1 : 0

  family                   = "${local.name_prefix}-jmeter-master"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.master_cpu
  memory                   = var.master_memory
  execution_role_arn       = var.ecs_task_exec_role_arn
  task_role_arn            = var.ecs_task_role_arn != null ? var.ecs_task_role_arn : var.ecs_task_exec_role_arn
  container_definitions    = jsonencode([local.master_container_definition])
  
  tags = var.tags
}

# Slave Task Definitions
resource "aws_ecs_task_definition" "slave" {
  count = var.slaves_count

  family                   = "${local.name_prefix}-jmeter-slave"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory
  execution_role_arn       = var.ecs_task_exec_role_arn
  task_role_arn            = var.ecs_task_role_arn != null ? var.ecs_task_role_arn : var.ecs_task_exec_role_arn
  container_definitions    = jsonencode([local.slave_container_definition])
  
  tags = var.tags
}