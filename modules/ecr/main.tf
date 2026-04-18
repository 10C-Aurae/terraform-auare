# ─────────────────────────────────────────────
#  Módulo: ecr
#  Repositorios privados de imágenes Docker (3 servicios)
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"

  repos = {
    backend   = "backend-service"
    aiservice = "ai-service"
    pwa       = "frontend-service"
  }
}

resource "aws_ecr_repository" "repos" {
  for_each = local.repos

  name                 = "${local.name_prefix}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${local.name_prefix}-${each.value}" }
}

resource "aws_ecr_lifecycle_policy" "repos" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name

  # Implementación lógica omitida por seguridad
  # Reglas: mantener últimas N imágenes tagged, expirar untagged > X días
}
