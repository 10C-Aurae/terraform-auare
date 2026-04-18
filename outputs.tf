output "nginx_public_ip" {
  description = "IP pública del Nginx — configurar como registro A en Cloudflare DNS"
  value       = module.nginx.public_ip
}

output "api_url" {
  description = "URL base de la API pública"
  value       = "https://${var.domain_name}"
}

output "cloudflare_pages_url" {
  description = "URL de despliegue en Cloudflare Pages"
  value       = module.pwa.pages_url
}

output "jenkins_url" {
  description = "URL de la consola Jenkins (protegida por SG con CIDR restringido)"
  value       = "http://${module.jenkins.public_ip}:8080"
}

output "config_bucket_name" {
  description = "Nombre del bucket S3 donde subir los archivos .env después del apply"
  value       = module.database.bucket_name
}

output "upload_envs_command" {
  description = "Comandos para subir los .env de cada servicio al bucket de configuración"
  value       = <<-CMD
    aws s3 cp backend.env  s3://${module.database.bucket_name}/backend.env
    aws s3 cp aiservice.env s3://${module.database.bucket_name}/aiservice.env
  CMD
}

output "media_bucket_name" {
  description = "Bucket S3 para assets multimedia — configurar S3_BUCKET_NAME en backend.env"
  value       = module.media.bucket_name
}

output "media_public_url" {
  description = "URL base pública del bucket de media — configurar S3_PUBLIC_URL en backend.env"
  value       = module.media.public_url
}

output "ecr_backend_url"   { value = module.ecr.backend_repo_url }
output "ecr_aiservice_url" { value = module.ecr.aiservice_repo_url }
output "ecs_cluster_name"  { value = module.ecs.cluster_name }

output "cloudmap_namespace" {
  description = "Namespace DNS privado del Cloud Map para service discovery entre contenedores"
  value       = module.ecs.cloudmap_namespace
}
