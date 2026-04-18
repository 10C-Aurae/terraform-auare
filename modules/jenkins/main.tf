# ─────────────────────────────────────────────
#  Módulo: jenkins
#
#  Servidor CI/CD en EC2 Spot con EBS persistente.
#
#  Decisión: Spot con EBS independiente de la instancia.
#  Si AWS interrumpe la instancia, el historial de builds
#  y la configuración de Jenkins sobreviven en el EBS.
#
#  SSM Parameter Store: almacena URLs de ECR y configuración
#  para que el user_data las lea sin hardcodear ARNs.
# ─────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# EBS persistente — datos de Jenkins (builds, plugins, config)
# lifecycle.prevent_destroy = true protege contra terraform destroy accidental
resource "aws_ebs_volume" "jenkins_data" {
  availability_zone = var.availability_zone
  size              = var.volume_size
  type              = "gp3"
  encrypted         = true

  tags = { Name = "${local.name_prefix}-jenkins-data" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.jenkins_sg_id]
  iam_instance_profile   = var.jenkins_instance_profile
  key_name               = var.key_pair_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  # Implementación lógica omitida por seguridad
  # user_data: instala Jenkins + Docker + monta EBS en JENKINS_HOME
  user_data = base64encode(file("${path.module}/user_data.sh"))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${local.name_prefix}-jenkins"
    Role = "cicd"
  }
}

resource "aws_volume_attachment" "jenkins_data" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.jenkins_data.id
  instance_id  = aws_instance.jenkins.id
  force_detach = true
}

resource "aws_eip" "jenkins" {
  instance   = aws_instance.jenkins.id
  domain     = "vpc"
  depends_on = [aws_instance.jenkins]

  tags = { Name = "${local.name_prefix}-jenkins-eip" }
}

# SSM Parameters — URLs de ECR accesibles desde el user_data sin hardcodear
resource "aws_ssm_parameter" "ecr_backend_url" {
  name  = "/${local.name_prefix}/ecr/backend-url"
  type  = "String"
  value = var.ecr_backend_url
}

resource "aws_ssm_parameter" "ecr_aiservice_url" {
  name  = "/${local.name_prefix}/ecr/aiservice-url"
  type  = "String"
  value = var.ecr_aiservice_url
}

resource "aws_ssm_parameter" "ecr_pwa_url" {
  name  = "/${local.name_prefix}/ecr/pwa-url"
  type  = "String"
  value = var.ecr_pwa_url
}

resource "aws_ssm_parameter" "aws_region" {
  name  = "/${local.name_prefix}/aws/region"
  type  = "String"
  value = var.aws_region
}

# Token de Cloudflare en SecureString — lo usa Nginx para certbot DNS challenge
resource "aws_ssm_parameter" "cf_api_token" {
  name  = "/${local.name_prefix}/cloudflare/api-token"
  type  = "SecureString"
  value = var.cloudflare_api_token

  lifecycle {
    ignore_changes = [value]
  }
}
