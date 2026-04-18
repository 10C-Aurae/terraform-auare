# ─────────────────────────────────────────────
#  Módulo: nginx
#
#  EC2 t3.micro Spot como reverse proxy.
#  Reemplaza el ALB ($18/mes) por ~$2/mes.
#
#  Responsabilidades:
#    - Terminar TLS (Let's Encrypt via certbot-dns-cloudflare)
#    - Proxy inverso hacia servicios ECS (via Cloud Map DNS)
#    - Registro DNS automático en Cloudflare (registro A)
#    - Cloudflare proxy ON → DDoS protection + CDN gratis
#
#  Decisión: Spot con interruption_behavior=stop + EIP persistente.
#  Si AWS interrumpe la instancia, el EIP y la config se mantienen.
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

resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.nginx_sg_id]
  iam_instance_profile   = var.nginx_instance_profile
  key_name               = var.key_pair_name

  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent"
    }
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  # Implementación lógica omitida por seguridad
  # user_data: instala Nginx + certbot + configuración de reverse proxy
  user_data = base64encode(file("${path.module}/user_data.sh"))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = { Name = "${local.name_prefix}-nginx" }
}

resource "aws_eip" "nginx" {
  instance   = aws_instance.nginx.id
  domain     = "vpc"
  depends_on = [aws_instance.nginx]

  tags = { Name = "${local.name_prefix}-nginx-eip" }
}

# Registro DNS automático en Cloudflare
# api.domain.com → IP pública del Nginx (con proxy CDN activado)
resource "cloudflare_record" "api" {
  zone_id = var.cf_zone_id
  name    = "api"
  content = aws_eip.nginx.public_ip
  type    = "A"
  proxied = true
  ttl     = 1
}
