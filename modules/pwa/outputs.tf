output "pages_url"      { value = "https://${cloudflare_pages_project.pwa.name}.pages.dev" }
output "pages_project"  { value = cloudflare_pages_project.pwa.name }
output "production_url" { value = "https://${var.domain_name}" }
