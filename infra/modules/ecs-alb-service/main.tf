# Runs an HTTP service on ECS Fargate behind a shared Application Load Balancer.

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158:CloudWatch Logs encrypts log data by default, and a customer-managed KMS key is deferred to the production hardening work.
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  skip_destroy      = var.keep_logs_on_destroy
}

locals {
  container_definition = {
    name                   = var.name
    image                  = var.image
    essential              = true
    readonlyRootFilesystem = true

    portMappings = [
      {
        containerPort = var.container_port
        protocol      = "tcp"
      },
    ]

    environment = [
      for name, value in var.environment : {
        name  = name
        value = value
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([local.container_definition])
}

resource "aws_ecs_service" "this" {
  name                              = var.name
  cluster                           = var.cluster_arn
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = var.health_check_grace_period
  wait_for_steady_state             = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  # Rolls back to the last working version if a deployment fails.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # The target group must be attached to the listener before the service uses it,
  # and the role must keep its permissions until the service is deleted.
  depends_on = [
    aws_lb_listener_rule.this,
    aws_iam_role_policy.task_execution,
  ]
}
