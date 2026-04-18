output "bucket_name"          { value = aws_s3_bucket.config.id }
output "bucket_arn"           { value = aws_s3_bucket.config.arn }
output "backend_env_s3_arn"   { value = "${aws_s3_bucket.config.arn}/backend.env" }
output "aiservice_env_s3_arn" { value = "${aws_s3_bucket.config.arn}/aiservice.env" }
