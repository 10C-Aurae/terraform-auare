# ─────────────────────────────────────────────
#  Módulo: database / config
#  Bucket S3 PRIVADO para archivos .env de los servicios
#
#  Patrón: ECS lee las variables de entorno directamente
#  desde S3 via "environmentFiles" en la task definition.
#  Esto elimina la necesidad de Secrets Manager (~$0.40/secret/mes)
#  y Parameter Store Advanced Tier.
#
#  Flujo post-apply:
#    aws s3 cp backend.env   s3://<bucket>/backend.env
#    aws s3 cp aiservice.env s3://<bucket>/aiservice.env
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
  bucket_name = "${local.name_prefix}-config"
}

resource "aws_s3_bucket" "config" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = { Name = "${local.name_prefix}-config" }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Placeholders — deben sobreescribirse con los .env reales post-apply
resource "aws_s3_object" "backend_env" {
  bucket       = aws_s3_bucket.config.id
  key          = "backend.env"
  content_type = "text/plain"

  # Implementación lógica omitida por seguridad
  # Formato ECS: KEY=VALUE (sin comillas, sin espacios alrededor del =)

  lifecycle {
    ignore_changes = [content, etag]
  }
}

resource "aws_s3_object" "aiservice_env" {
  bucket       = aws_s3_bucket.config.id
  key          = "aiservice.env"
  content_type = "text/plain"

  # Implementación lógica omitida por seguridad

  lifecycle {
    ignore_changes = [content, etag]
  }
}
