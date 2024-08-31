# This variable defines the AWS Region.
variable "region" {
  description = "region to use for AWS resources"
  type        = string
  default     = "eu-west-1"
}

variable "global_prefix" {
  type    = string
  default = "dsti-msk-test"
}

variable "private_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]
}

variable "cidr_blocks_bastion_host" {
  type = list(string)
  default = ["10.0.4.0/24"]
}

variable "cidr_blocks_ec2_data_producer" {
  type = list(string)
  default = ["10.0.5.0/24"]
}

variable "cidr_blocks_kafka_consumer" {
  type = list(string)
  default = ["10.0.6.0/24"]
}

variable "SKYSCANNER_API_KEY" {
  description = "API key for accessing Skyscanner API"
  type        = string
  sensitive   = true
}

variable "TOPIC_NAME" {
  type    = String
  default = "flight-kafka-topic"
}


