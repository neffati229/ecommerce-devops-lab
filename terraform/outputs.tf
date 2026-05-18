output "instance_public_ips" {
  description = "Public IPs of EC2 instances"
  value = [
    aws_instance.web1.public_ip,
    aws_instance.web2.public_ip
  ]
}

output "instance_public_ip_1" {
  description = "Public IP of first EC2 instance"
  value = aws_instance.web1.public_ip
}

output "instance_public_ip_2" {
  description = "Public IP of second EC2 instance"
  value = aws_instance.web2.public_ip
}
