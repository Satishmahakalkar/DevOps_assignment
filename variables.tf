# outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "web_app_subnet_id" {
  description = "The ID of the Web App Subnet"
  value       = aws_subnet.web_app_subnet.id
}

output "db_subnet_id" {
  description = "The ID of the DB Subnet"
  value       = aws_subnet.db_subnet.id
}

output "web_app_instance_id" {
  description = "The ID of the Web App Instance"
  value       = aws_instance.web_app.id
}

output "db_instance_id" {
  description = "The ID of the DB Instance"
  value       = aws_instance.db.id
}

output "bastion_instance_id" {
  description = "The ID of the Bastion Instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "The public IP of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}
