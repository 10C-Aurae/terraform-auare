# ─────────────────────────────────────────────
#  Módulo: security
#
#  Security Groups:
#    - nginx-sg    : HTTP/HTTPS público → EC2 Nginx
#    - ecs-sg      : Puertos de app SOLO desde Nginx SG
#    - jenkins-sg  : UI + SSH restringido a IP del equipo
#
#  IAM Roles:
#    - ecs-execution-role  : Pull de ECR + leer .env de S3
#    - ecs-task-role       : Permisos runtime (S3 media, CloudWatch)
#    - jenkins-role        : ECR push/pull + ECS deploy + S3 config
#    - nginx-role          : Lectura de parámetros SSM
#    - github-actions-role : OIDC trust → CI/CD sin access keys
#
#  Decisión: sin WAF (~$10/mes) — Cloudflare proxy absorbe DDoS.
#  Decisión: sin KMS custom (~$1/clave) — AES256 gestionado por AWS.
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ══════════════════════════════════════════════
#  SECURITY GROUPS
# ══════════════════════════════════════════════

# EC2 Nginx — reemplaza ALB como punto de entrada público
resource "aws_security_group" "nginx" {
  name        = "${local.name_prefix}-nginx-sg"
  description = "Nginx reverse proxy — HTTP/HTTPS público"
  vpc_id      = var.vpc_id

  # Implementación lógica omitida por seguridad
  # Reglas: ingress 80/443 desde 0.0.0.0/0, egress all
  tags = { Name = "${local.name_prefix}-nginx-sg" }
}

# Tareas ECS — solo accesibles desde el Security Group de Nginx
resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "ECS Fargate — tráfico permitido solo desde Nginx SG"
  vpc_id      = var.vpc_id

  # Implementación lógica omitida por seguridad
  # Reglas: ingress 8000 (backend) y 8001 (aiservice) desde nginx-sg
  tags = { Name = "${local.name_prefix}-ecs-sg" }
}

# Jenkins — restringido a IP del equipo de desarrollo
resource "aws_security_group" "jenkins" {
  name        = "${local.name_prefix}-jenkins-sg"
  description = "Jenkins — acceso restringido a CIDR del equipo"
  vpc_id      = var.vpc_id

  # Implementación lógica omitida por seguridad
  # Reglas: ingress 8080/22/50000 desde jenkins_allowed_cidr
  tags = { Name = "${local.name_prefix}-jenkins-sg" }
}

# ══════════════════════════════════════════════
#  IAM — ECS Execution Role
#  Permite a ECS: pull de ECR + leer .env desde S3
# ══════════════════════════════════════════════

resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  # Implementación lógica omitida por seguridad
  # Trust policy: ecs-tasks.amazonaws.com
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_execution_s3_env" {
  name        = "${local.name_prefix}-ecs-exec-s3-env"
  description = "Permite a ECS leer archivos .env desde S3"

  # Implementación lógica omitida por seguridad
  # Acciones: s3:GetObject sobre el bucket de configuración
}

resource "aws_iam_role_policy_attachment" "ecs_execution_s3_env" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_s3_env.arn
}

# ══════════════════════════════════════════════
#  IAM — ECS Task Role (permisos en runtime)
#  CloudWatch Logs + métricas + S3 media
# ══════════════════════════════════════════════

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  # Implementación lógica omitida por seguridad
  # Trust policy: ecs-tasks.amazonaws.com
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "${local.name_prefix}-ecs-task-policy"

  # Implementación lógica omitida por seguridad
  # Acciones: logs:*, cloudwatch:PutMetricData
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# ══════════════════════════════════════════════
#  IAM — Jenkins Role
#  ECR push/pull + ECS deploy + S3 config + SSM
# ══════════════════════════════════════════════

resource "aws_iam_role" "jenkins" {
  name = "${local.name_prefix}-jenkins-role"

  # Implementación lógica omitida por seguridad
  # Trust policy: ec2.amazonaws.com
}

resource "aws_iam_policy" "jenkins_policy" {
  name = "${local.name_prefix}-jenkins-policy"

  # Implementación lógica omitida por seguridad
  # Permisos: ECRAuth, ECRPushPull, ECSDeployment,
  #           IAM:PassRole, S3EnvConfig, CloudWatchLogs, SSMReadOnly
}

resource "aws_iam_role_policy_attachment" "jenkins" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

# ── Nginx Role — solo lectura de parámetros SSM ──

resource "aws_iam_role" "nginx" {
  name = "${local.name_prefix}-nginx-role"

  # Implementación lógica omitida por seguridad
  # Trust policy: ec2.amazonaws.com
}

resource "aws_iam_policy" "nginx_policy" {
  name = "${local.name_prefix}-nginx-policy"

  # Implementación lógica omitida por seguridad
  # Acciones: ssm:GetParameter sobre parámetros del proyecto
}

resource "aws_iam_role_policy_attachment" "nginx" {
  role       = aws_iam_role.nginx.name
  policy_arn = aws_iam_policy.nginx_policy.arn
}

resource "aws_iam_role_policy_attachment" "nginx_ssm" {
  role       = aws_iam_role.nginx.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nginx" {
  name = "${local.name_prefix}-nginx-profile"
  role = aws_iam_role.nginx.name
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${local.name_prefix}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# ══════════════════════════════════════════════
#  GitHub Actions — OIDC (sin access keys estáticos)
#  Los workflows asumen el rol via sts:AssumeRoleWithWebIdentity
#  usando el JWT que genera GitHub en cada job.
# ══════════════════════════════════════════════

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${local.name_prefix}-github-actions-deploy"

  # Implementación lógica omitida por seguridad
  # Trust: OIDC federated → repo:${var.github_org}/*:*
}

resource "aws_iam_policy" "github_actions_deploy" {
  name = "${local.name_prefix}-github-actions-deploy-policy"

  # Implementación lógica omitida por seguridad
  # Permisos: ECRAuth, ECRPushPull, ECSDeployment, IAM:PassRole
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}
