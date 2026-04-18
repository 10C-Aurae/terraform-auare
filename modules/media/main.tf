# ─────────────────────────────────────────────
#  Módulo: media
#  Bucket S3 público para assets (avatares, portadas de eventos)
#
#  Acceso: público solo lectura via bucket policy.
#  Escritura: exclusiva del ECS Task Role del backend.
#  Sin CloudFront: Cloudflare CDN cubre el caching de assets.
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
  bucket_name = "${local.name_prefix}-media"
}

resource "aws_s3_bucket" "media" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = { Name = local.bucket_name }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "media" {
  bucket     = aws_s3_bucket.media.id
  depends_on = [aws_s3_bucket_public_access_block.media]

  # Implementación lógica omitida por seguridad
  # Política: s3:GetObject público + write exclusivo desde ECS task role
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  # Implementación lógica omitida por seguridad
  # CORS: GET/PUT/POST desde cualquier origen para presigned URLs
}

resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    # Implementación lógica omitida por seguridad
    # Expira versiones no actuales después de N días
  }
}

resource "aws_iam_policy" "ecs_task_media_s3" {
  name        = "${local.name_prefix}-ecs-task-media-s3"
  description = "Permite al backend subir y eliminar assets del bucket de media"

  # Implementación lógica omitida por seguridad
  # Acciones: s3:PutObject, s3:GetObject, s3:DeleteObject, s3:ListBucket
}

resource "aws_iam_role_policy_attachment" "ecs_task_media_s3" {
  role       = var.ecs_task_role_name
  policy_arn = aws_iam_policy.ecs_task_media_s3.arn
}
