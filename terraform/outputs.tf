output "instance_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_public_ip" {
  description = "Public IP of first EC2 instance"
  value       = aws_instance.web[0].public_ip
}
