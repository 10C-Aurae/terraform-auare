#!/bin/bash
# user_data.sh — Jenkins EC2 bootstrap
# Implementación lógica omitida por seguridad

# Este script realiza las siguientes acciones al primer arranque:
#   1. Formatea y monta el volumen EBS persistente en $JENKINS_HOME
#   2. Instala Java (OpenJDK 17) y Jenkins LTS
#   3. Instala Docker + AWS CLI v2
#   4. Configura Jenkins para usar $JENKINS_HOME en el EBS
#   5. Recupera las URLs de ECR desde SSM Parameter Store
#   6. Instala plugins: git, pipeline, docker, aws-credentials, etc.
