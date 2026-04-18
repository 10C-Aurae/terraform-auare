# ─────────────────────────────────────────────
#  Módulo: ecs
#
#  Cluster Fargate con dos servicios: backend + aiservice.
#
#  Decisiones de costo:
#    FARGATE_SPOT   : ~70% más barato (weight 4 vs 1 on-demand)
#    assign_public_ip: true → sin NAT Gateway
#    .env desde S3  : sin Secrets Manager ni Parameter Store de pago
#    Cloud Map DNS  : service discovery interno sin ALB
#
#  Auto Scaling: CPU-based TargetTracking en ambos servicios
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_region" "current" {}

# ── ECS Cluster ───────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # Implementación lógica omitida por seguridad
  # Estrategia: SPOT weight=4 base=0, ON_DEMAND weight=1 base=1
}

# ── Cloud Map — service discovery DNS privado ──
# Crea el namespace DNS privado en la VPC.
# Nginx resuelve los servicios como: backend.app.local, aiservice.app.local

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "app.local"
  vpc  = var.vpc_id

  tags = { Name = "${local.name_prefix}-cloudmap" }
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.main.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_service_discovery_service" "aiservice" {
  name = "aiservice"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.main.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

# ── CloudWatch Log Groups ─────────────────────

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}/backend-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "aiservice" {
  name              = "/ecs/${local.name_prefix}/ai-service"
  retention_in_days = 7
}

# ══════════════════════════════════════════════
#  Servicio: backend
# ══════════════════════════════════════════════

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  task_role_arn            = var.ecs_task_role_arn
  execution_role_arn       = var.ecs_execution_role_arn

  # Implementación lógica omitida por seguridad
  # Incluye: portMappings, environmentFiles (S3), logConfiguration, healthCheck
  container_definitions = "[]"
}

resource "aws_ecs_service" "backend" {
  name            = "${local.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count

  # Implementación lógica omitida por seguridad
  # capacity_provider_strategy: FARGATE_SPOT + FARGATE fallback
  # deployment_circuit_breaker + rollback habilitado

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = { Name = "${local.name_prefix}-backend-svc" }
}

resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 4
  min_capacity       = var.backend_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "${local.name_prefix}-backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  # Implementación lógica omitida por seguridad
  # Política: ECSServiceAverageCPUUtilization target ~70%
}

# ══════════════════════════════════════════════
#  Servicio: aiservice
# ══════════════════════════════════════════════

resource "aws_ecs_task_definition" "aiservice" {
  family                   = "${local.name_prefix}-aiservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.aiservice_cpu
  memory                   = var.aiservice_memory
  task_role_arn            = var.ecs_task_role_arn
  execution_role_arn       = var.ecs_execution_role_arn

  # Implementación lógica omitida por seguridad
  container_definitions = "[]"
}

resource "aws_ecs_service" "aiservice" {
  name            = "${local.name_prefix}-aiservice"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.aiservice.arn
  desired_count   = var.aiservice_desired_count

  # Implementación lógica omitida por seguridad

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.aiservice.arn
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = { Name = "${local.name_prefix}-aiservice-svc" }
}

resource "aws_appautoscaling_target" "aiservice" {
  max_capacity       = 3
  min_capacity       = var.aiservice_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.aiservice.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "aiservice_cpu" {
  name               = "${local.name_prefix}-aiservice-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aiservice.resource_id
  scalable_dimension = aws_appautoscaling_target.aiservice.scalable_dimension
  service_namespace  = aws_appautoscaling_target.aiservice.service_namespace

  # Implementación lógica omitida por seguridad
}
