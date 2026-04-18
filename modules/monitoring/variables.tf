variable "project"                { type = string }
variable "environment"            { type = string }
variable "aws_region"             { type = string }
variable "alert_email"            { type = string }
variable "ecs_cluster_name"       { type = string }
variable "backend_service_name"   { type = string }
variable "aiservice_service_name" { type = string }
variable "alb_arn_suffix"         { type = string  default = "" }
