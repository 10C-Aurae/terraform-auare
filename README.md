# terraform-aurae

> **ARCHITECTURE DESIGN BY:** Yunuen M.  
> **VERSION:** Academic Evaluation Only  
> **WARNING:** This configuration is a structural template. Full orchestration logic, security groups, and CI/CD pipelines are proprietary and not included in this public repository.

---

## Overview

Infrastructure-as-Code (IaC) skeleton for a cloud-native event platform deployed on AWS.  
Designed for low-budget production environments using cost-optimized AWS services.

## Cost Optimization Decisions

| Service removed | Replacement | Savings |
|-----------------|-------------|---------|
| ALB | Nginx EC2 Spot t3.micro | ~$16/mes |
| NAT Gateway | `assign_public_ip = true` en ECS | ~$35/mes |
| WAF | Cloudflare proxy (free tier) | ~$10/mes |
| Secrets Manager | S3 `.env` via `environmentFiles` | ~$2/mes |
| CloudFront | Cloudflare Pages CDN (free) | ~$1+/mes |

## Module Structure

```
terraform-aurae/
├── main.tf              # Composición de módulos
├── variables.tf         # Variables globales
├── outputs.tf           # Outputs del stack
├── versions.tf          # Providers: AWS, Cloudflare
└── modules/
    ├── networking/      # VPC, subnets públicas, IGW
    ├── security/        # Security Groups + IAM Roles
    ├── ecr/             # Container registries (3 servicios)
    ├── ecs/             # Cluster Fargate + Cloud Map
    ├── nginx/           # EC2 Spot reverse proxy
    ├── jenkins/         # EC2 Spot CI/CD + EBS persistente
    ├── media/           # S3 bucket assets públicos
    ├── database/        # S3 bucket configuración .env
    ├── monitoring/      # CloudWatch + SNS alertas
    └── pwa/             # Cloudflare Pages deployment
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

terraform init
terraform plan
terraform apply
```

## Post-Apply Steps

1. Obtener `nginx_public_ip` del output y configurar registro A en Cloudflare DNS
2. Subir variables de entorno al bucket de configuración:
   ```bash
   aws s3 cp backend.env   s3://<config_bucket>/backend.env
   aws s3 cp aiservice.env s3://<config_bucket>/aiservice.env
   ```
3. Push a `main` → Jenkins construye imágenes y despliega en ECS

---

*Academic project — Infrastructure template only. Proprietary implementation details omitted.*
