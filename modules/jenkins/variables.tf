variable "project"                   { type = string }
variable "environment"               { type = string }
variable "vpc_id"                    { type = string }
variable "public_subnet_id"          { type = string }
variable "availability_zone"         { type = string }
variable "jenkins_sg_id"             { type = string }
variable "jenkins_role_arn"          { type = string }
variable "jenkins_instance_profile"  { type = string }
variable "instance_type"             { type = string }
variable "volume_size"               { type = number }
variable "key_pair_name"             { type = string }
variable "ecr_backend_url"           { type = string }
variable "ecr_aiservice_url"         { type = string }
variable "ecr_pwa_url"               { type = string }
variable "aws_region"                { type = string }
variable "cloudflare_api_token"      {
  type      = string
  sensitive = true
}
