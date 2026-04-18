output "cluster_name"           { value = aws_ecs_cluster.main.name }
output "cluster_arn"            { value = aws_ecs_cluster.main.arn }
output "backend_service_name"   { value = aws_ecs_service.backend.name }
output "aiservice_service_name" { value = aws_ecs_service.aiservice.name }
output "cloudmap_namespace"     { value = aws_service_discovery_private_dns_namespace.main.name }
