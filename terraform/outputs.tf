output "instance_public_ip" {
  value = [
    aws_instance.web1.public_ip,
    aws_instance.web2.public_ip,
  ]
}