# ─────────────────────────────────────────────
#  Variables globales
# ─────────────────────────────────────────────

variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nombre del entorno (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Nombre del proyecto — prefijo de todos los recursos"
  type        = string
  default     = "myapp"
}

# ── Networking ─────────────────────────────────
# Decisión: sin subnets privadas para evitar el costo de NAT Gateway ($32+/mes).
# ECS usa subnets públicas con assign_public_ip = true.
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Al menos 2 AZs para alta disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

# ── Dominio ────────────────────────────────────
variable "domain_name" {
  description = "Dominio base de la aplicación"
  type        = string
  default     = "your-app.example"
}

# ── Cloudflare ────────────────────────────────
variable "cloudflare_api_token" {
  description = "Token de Cloudflare con permisos: Pages:Edit, DNS:Edit, Zone:Read"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "ID de la cuenta de Cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID de Cloudflare para el dominio"
  type        = string
}

# ── Jenkins ───────────────────────────────────
variable "jenkins_instance_type" {
  description = "Tipo de instancia EC2 para Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_volume_size" {
  description = "Tamaño del EBS persistente de Jenkins en GB"
  type        = number
  default     = 30
}

variable "jenkins_allowed_cidr" {
  description = "CIDR /32 de tu IP pública para acceder a Jenkins y SSH"
  type        = string
}

variable "key_pair_name" {
  description = "Nombre del Key Pair de EC2 para SSH"
  type        = string
}

# ── ECS Services ──────────────────────────────
variable "backend_image" {
  description = "URI completa de imagen Docker para el backend (vacío = usar ECR)"
  type        = string
  default     = ""
}

variable "aiservice_image" {
  description = "URI completa de imagen Docker para el AI service (vacío = usar ECR)"
  type        = string
  default     = ""
}

variable "backend_cpu" {
  description = "CPU units para Fargate (256 = 0.25 vCPU, mínimo)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memoria en MB para Fargate (mínimo con cpu=256)"
  type        = number
  default     = 512
}

variable "aiservice_cpu" {
  type    = number
  default = 512
}

variable "aiservice_memory" {
  type    = number
  default = 1024
}

variable "backend_desired_count" {
  description = "Número de tareas ECS deseadas para el backend"
  type        = number
  default     = 1
}

variable "aiservice_desired_count" {
  type    = number
  default = 1
}

# ── GitHub OIDC ───────────────────────────────
variable "github_org" {
  description = "Usuario u organización de GitHub para OIDC (sin access keys)"
  type        = string
}

# ── Alertas ───────────────────────────────────
variable "alert_email" {
  description = "Email para recibir alertas de CloudWatch via SNS"
  type        = string
}
