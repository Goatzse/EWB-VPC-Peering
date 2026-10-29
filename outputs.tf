output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "app_a_private_ip" {
  value = aws_instance.app_a.private_ip
}

output "app_b_private_ip" {
  value = aws_instance.app_b.private_ip
}

output "vpc_a_id" {
  value = aws_vpc.vpc_a.id
}

output "vpc_b_id" {
  value = aws_vpc.vpc_b.id
}

output "peering_connection_id" {
  value = aws_vpc_peering_connection.a_b.id
}
