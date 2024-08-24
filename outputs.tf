################################################################################
# Client Machine (EC2 instance)
################################################################################
output "execute_this_to_access_the_bastion_host" {
  value = "ssh ec2-user@${aws_instance.bastion_host.public_ip} -i cert.pem"
}
