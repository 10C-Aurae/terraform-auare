output "backend_repo_url"   { value = aws_ecr_repository.repos["backend"].repository_url }
output "aiservice_repo_url" { value = aws_ecr_repository.repos["aiservice"].repository_url }
output "pwa_repo_url"       { value = aws_ecr_repository.repos["pwa"].repository_url }
