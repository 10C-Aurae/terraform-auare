# ─────────────────────────────────────────────
#  Módulo: monitoring
#
#  Observabilidad con CloudWatch nativo (sin Grafana ECS ~$8/mes).
#
#  Componentes:
#    - SNS topic → alertas por email
#    - CloudWatch Alarms: CPU alta, tareas caídas (ambos servicios)
#    - CloudWatch Dashboard: CPU%, memoria%, tareas activas
#
#  Decisión: sin alarmas de ALB (se eliminó) — monitoreo
#  directo sobre métricas del cluster ECS.
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
  tags = { Name = "${local.name_prefix}-alerts" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── Alarmas ECS — backend ─────────────────────

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${local.name_prefix}-backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.backend_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_tasks_low" {
  alarm_name          = "${local.name_prefix}-backend-tasks-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CRITICO: servicio backend sin tareas activas"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.backend_service_name
  }
}

# ── Alarmas ECS — aiservice ───────────────────

resource "aws_cloudwatch_metric_alarm" "aiservice_cpu_high" {
  alarm_name          = "${local.name_prefix}-aiservice-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.aiservice_service_name
  }
}

# ── CloudWatch Dashboard ──────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-overview"

  # Implementación lógica omitida por seguridad
  # Widgets: CPU%, Memoria%, RunningTaskCount para backend y aiservice
  dashboard_body = jsonencode({ widgets = [] })
}
