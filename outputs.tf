################################################################################
# Client Machine (EC2 instance)
################################################################################
output "execute_this_to_access_the_bastion_host" {
  value = "ssh ec2-user@${aws_instance.bastion_host.public_ip} -i cert.pem"
}
output "execute_this_to_copy_access_key_into_bastion_host" {
  value = "scp -i /your_local_path_to/cert.pem /your_local_path_to/cert.pem ec2-user@${aws_instance.bastion_host.public_ip}:/home/ec2-user/"
}
output "execute_this_to_access_the_ec2_data_producer" {
  value       = "ssh ec2-user@${aws_instance.data_producer.public_ip} -i cert.pem"
}
