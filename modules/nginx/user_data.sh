#!/bin/bash
# user_data.sh — Nginx EC2 bootstrap
# Implementación lógica omitida por seguridad

# Este script realiza las siguientes acciones al primer arranque:
#   1. Instala Nginx, Certbot y el plugin certbot-dns-cloudflare
#   2. Obtiene y configura el certificado TLS via DNS challenge con Cloudflare
#   3. Genera la configuración de Nginx como reverse proxy hacia:
#        backend.app.local:8000   (resuelto via Cloud Map DNS)
#        aiservice.app.local:8001 (resuelto via Cloud Map DNS)
#   4. Configura cron para renovación automática del certificado
#   5. Habilita el servicio Nginx al reinicio
