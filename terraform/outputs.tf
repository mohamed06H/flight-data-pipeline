################################################################################
# Client Machine (EC2 instance)
################################################################################
output "execute_this_to_access_the_bastion_host" {
  value = "ssh ec2-user@${aws_instance.bastion_host.public_ip} -i cert.pem"
}

output "execute_this_to_access_the_ec2_data_producer" {
  value       = "ssh ec2-user@${aws_instance.data_producer.public_ip} -i cert.pem"
}

output "execute_this_to_access_the_kafka_consumer" {
  value       = "ssh ec2-user@${aws_instance.kafka_consumer.public_ip} -i cert.pem"
}