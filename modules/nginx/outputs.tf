output "public_ip"   { value = aws_eip.nginx.public_ip }
output "instance_id" { value = aws_instance.nginx.id }
output "eip_id"      { value = aws_eip.nginx.id }
