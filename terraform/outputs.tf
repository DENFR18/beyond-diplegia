output "ec2_public_ip" {
  description = "IP publique de l'EC2 (utilisée par Ansible pour l'inventaire)"
  value       = aws_eip.web.public_ip
}

output "ec2_public_dns" {
  description = "DNS public de l'EC2"
  value       = aws_eip.web.public_dns
}
