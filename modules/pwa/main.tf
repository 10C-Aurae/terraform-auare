# ─────────────────────────────────────────────
#  Módulo: pwa
#  Frontend desplegado en Cloudflare Pages (CDN gratuito)
#
#  Terraform gestiona: proyecto Pages + dominios personalizados.
#  El deploy del contenido (wrangler pages deploy) lo hace
#  el pipeline CI/CD en cada push a main.
#
#  Decisión: Cloudflare Pages en lugar de S3+CloudFront (~$1+/mes).
#  Tier gratuito: 500 builds/mes, CDN global, SSL automático.
# ─────────────────────────────────────────────

locals {
  name_prefix  = "${var.project}-${var.environment}"
  project_name = "${var.project}-pwa"
}

resource "cloudflare_pages_project" "pwa" {
  account_id        = var.cloudflare_account_id
  name              = local.project_name
  production_branch = "main"

  # Implementación lógica omitida por seguridad
  # build_config: comando, directorio de salida, root
  # deployment_configs: variables de entorno del build (NODE_VERSION, VITE_API_URL)
}

# Dominio personalizado en Cloudflare Pages
resource "cloudflare_pages_domain" "apex" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.pwa.name
  domain       = var.domain_name
}

resource "cloudflare_pages_domain" "www" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.pwa.name
  domain       = "www.${var.domain_name}"
}
