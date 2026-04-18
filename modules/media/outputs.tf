output "bucket_name" { value = aws_s3_bucket.media.id }
output "bucket_arn"  { value = aws_s3_bucket.media.arn }
output "public_url"  { value = "https://${aws_s3_bucket.media.id}.s3.${var.region}.amazonaws.com" }
