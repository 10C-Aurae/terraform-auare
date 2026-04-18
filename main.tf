# =============================================================================
# ARCHITECTURE DESIGN BY: Yunuen M.
# VERSION: Academic Evaluation Only
# WARNING: This configuration is a structural template.
# Full orchestration logic, security groups, and CI/CD pipelines
# are proprietary and not included in this public repository.
# =============================================================================

# ─────────────────────────────────────────────
#  main.tf — Arquitectura de referencia
#
#  Patrón de bajo costo (presupuesto estudiantil):
#    PWA  : Cloudflare Pages (CDN gratuito)
#    API  : Nginx EC2 Spot como reverse proxy (sin ALB)
#    ECS  : Fargate Spot + Cloud Map service discovery
#    DB   : MongoDB Atlas SaaS (sin RDS)
#    CI/CD: Jenkins EC2 Spot con EBS persistente
#
#  Servicios eliminados deliberadamente para reducir costo:
#    ✗ ALB  (~$18/mes)   → reemplazado por Nginx EC2 Spot
#    ✗ NAT  (~$35/mes)   → ECS usa assign_public_ip en subnet pública
#    ✗ WAF  (~$10/mes)   → Cloudflare proxy como capa de protección
#    ✗ KMS  (~$1/clave)  → SSE-S3 (AES256 gestionado por AWS)
# ─────────────────────────────────────────────

module "networking" {
  source = "./modules/networking"

  project             = var.project
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "security" {
  source = "./modules/security"

  project              = var.project
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  jenkins_allowed_cidr = var.jenkins_allowed_cidr
  github_org           = var.github_org
}

module "ecr" {
  source = "./modules/ecr"

  project     = var.project
  environment = var.environment
}

# Bucket S3 público para assets multimedia (avatares, portadas de eventos)
module "media" {
  source = "./modules/media"

  project            = var.project
  environment        = var.environment
  region             = var.aws_region
  ecs_task_role_name = module.security.ecs_task_role_name
}

# Bucket S3 privado para archivos .env de cada servicio
module "database" {
  source = "./modules/database"

  project     = var.project
  environment = var.environment
}

module "ecs" {
  source = "./modules/ecs"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  ecs_security_group_id = module.security.ecs_sg_id

  backend_image   = var.backend_image != "" ? var.backend_image : "${module.ecr.backend_repo_url}:latest"
  aiservice_image = var.aiservice_image != "" ? var.aiservice_image : "${module.ecr.aiservice_repo_url}:latest"

  backend_cpu    = var.backend_cpu
  backend_memory = var.backend_memory
  aiservice_cpu    = var.aiservice_cpu
  aiservice_memory = var.aiservice_memory

  backend_desired_count   = var.backend_desired_count
  aiservice_desired_count = var.aiservice_desired_count

  ecs_task_role_arn      = module.security.ecs_task_role_arn
  ecs_execution_role_arn = module.security.ecs_execution_role_arn

  config_bucket_arn    = module.database.bucket_arn
  backend_env_s3_arn   = module.database.backend_env_s3_arn
  aiservice_env_s3_arn = module.database.aiservice_env_s3_arn
}

# Nginx EC2 Spot — reverse proxy frente a los servicios ECS
# Obtiene TLS gratis via Let's Encrypt + certbot-dns (sin ACM)
module "nginx" {
  source = "./modules/nginx"

  project                = var.project
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnet_id       = module.networking.public_subnet_ids[0]
  availability_zone      = var.availability_zones[0]
  nginx_sg_id            = module.security.nginx_sg_id
  nginx_instance_profile = module.security.nginx_instance_profile_name
  key_pair_name          = var.key_pair_name
  domain_name            = var.domain_name
  aws_region             = var.aws_region
  cf_zone_id             = var.cloudflare_zone_id
}

# PWA desplegada en Cloudflare Pages (CDN global gratuito)
module "pwa" {
  source = "./modules/pwa"

  project               = var.project
  environment           = var.environment
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  domain_name           = var.domain_name
}

# Jenkins EC2 Spot con EBS persistente para CI/CD
# AZ distinta a Nginx para evitar punto único de fallo
module "jenkins" {
  source = "./modules/jenkins"

  project                  = var.project
  environment              = var.environment
  vpc_id                   = module.networking.vpc_id
  public_subnet_id         = module.networking.public_subnet_ids[1]
  availability_zone        = var.availability_zones[1]
  jenkins_sg_id            = module.security.jenkins_sg_id
  jenkins_role_arn         = module.security.jenkins_role_arn
  jenkins_instance_profile = module.security.jenkins_instance_profile_name

  instance_type        = var.jenkins_instance_type
  volume_size          = var.jenkins_volume_size
  key_pair_name        = var.key_pair_name
  cloudflare_api_token = var.cloudflare_api_token

  ecr_backend_url   = module.ecr.backend_repo_url
  ecr_aiservice_url = module.ecr.aiservice_repo_url
  ecr_pwa_url       = module.ecr.pwa_repo_url
  aws_region        = var.aws_region
}

# Alarmas CloudWatch + SNS + Dashboard de observabilidad
module "monitoring" {
  source = "./modules/monitoring"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  alert_email = var.alert_email

  ecs_cluster_name       = module.ecs.cluster_name
  backend_service_name   = module.ecs.backend_service_name
  aiservice_service_name = module.ecs.aiservice_service_name

  alb_arn_suffix = "" # Sin ALB — monitoreo directo sobre métricas ECS
}
