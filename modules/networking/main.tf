# ─────────────────────────────────────────────
#  Módulo: networking
#
#  Arquitectura: VPC con subnets SOLO públicas (sin privadas).
#  Decisión: se elimina NAT Gateway (~$35/mes).
#  Contrapartida: ECS usa assign_public_ip = true.
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Implementación lógica omitida por seguridad
  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  # Implementación lógica omitida por seguridad
  # Subnets públicas multi-AZ con map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}-public-${count.index + 1}" }
}

resource "aws_internet_gateway" "main" {
  # Implementación lógica omitida por seguridad
  tags = { Name = "${local.name_prefix}-igw" }
}

resource "aws_route_table" "public" {
  # Implementación lógica omitida por seguridad
  # Incluye ruta default 0.0.0.0/0 → Internet Gateway
  tags = { Name = "${local.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  # Implementación lógica omitida por seguridad
}

data "aws_region" "current" {}
