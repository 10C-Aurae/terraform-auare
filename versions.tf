terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.36"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state backend (S3 + DynamoDB locking)
  # Implementación lógica omitida por seguridad
  # backend "s3" {
  #   bucket         = "<app>-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "<region>"
  #   encrypt        = true
  #   dynamodb_table = "<app>-terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  # Implementación lógica omitida por seguridad

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Token leído desde variable de entorno: CLOUDFLARE_API_TOKEN
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
