################################################################################
# Cluster
################################################################################
resource "aws_kms_key" "kafka_kms_key" {
  description = "Key for Apache Kafka"
}

resource "aws_cloudwatch_log_group" "kafka_log_group" {
  name = "kafka_broker_logs"
}

resource "aws_msk_configuration" "kafka_config" {
  kafka_versions    = ["2.8.1"] # 3.5.1 the recomended one at https://docs.aws.amazon.com/msk/latest/developerguide/supported-kafka-versions.html
  name              = "${var.global_prefix}-config"
  server_properties = <<EOF
auto.create.topics.enable = true
delete.topic.enable = true
EOF
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = var.global_prefix
  kafka_version          = "2.8.1"
  number_of_broker_nodes = length(data.aws_availability_zones.available.names)
  broker_node_group_info {
    instance_type = "kafka.t3.small" # production value: kafka.m5.large
    storage_info {
      ebs_storage_info {
        volume_size = 10 # production value: 1000
      }
    }
    client_subnets = [aws_subnet.private_subnet[0].id,
      aws_subnet.private_subnet[1].id,
    aws_subnet.private_subnet[2].id]
    security_groups = [aws_security_group.kafka.id]
  }
  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
    }
    encryption_at_rest_kms_key_arn = aws_kms_key.kafka_kms_key.arn
  }
  configuration_info {
    arn      = aws_msk_configuration.kafka_config.arn
    revision = aws_msk_configuration.kafka_config.latest_revision
  }
  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.kafka_log_group.name
      }
    }
  }
}

################################################################################
# General
################################################################################
/*
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [aws_route_table.private_route_table.id]

  tags = {
    Name = "${var.global_prefix}-S3Endpoint"
  }
}
 */
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "default" {
  depends_on = [aws_internet_gateway.default]
  domain     = "vpc"
}

resource "aws_route" "default" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}
/*
resource "aws_route_table_association" "kafka_consumer_subnet_association" {
  subnet_id      = aws_subnet.kafka_consumer_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
*/
################################################################################
# Subnets
################################################################################

resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_cidr_blocks)
  vpc_id                  = aws_vpc.default.id
  cidr_block              = element(var.private_cidr_blocks, count.index)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "bastion_host_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.cidr_blocks_bastion_host[0]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "ec2_data_producer_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.cidr_blocks_ec2_data_producer[0]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "kafka_consumer_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.cidr_blocks_kafka_consumer[0]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

################################################################################
# Security groups
################################################################################

resource "aws_security_group" "kafka" {
  name   = "${var.global_prefix}-kafka"
  vpc_id = aws_vpc.default.id
  ingress {
    from_port   = 0
    to_port     = 9092
    protocol    = "TCP"
    cidr_blocks = var.private_cidr_blocks
  }
  ingress {
    from_port   = 0
    to_port     = 9092
    protocol    = "TCP"
    cidr_blocks = var.cidr_blocks_bastion_host
  }
  ingress {
      from_port   = 0
      to_port     = 9092
      protocol    = "TCP"
      cidr_blocks = var.cidr_blocks_ec2_data_producer
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion_host" {
  name   = "${var.global_prefix}-bastion-host"
  vpc_id = aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_data_producer" {
  name   = "${var.global_prefix}-ec2-data-producer"
  vpc_id = aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kafka_consumer_sg" {
  name   = "${var.global_prefix}-kafka-consumer-sg"
  vpc_id = aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "private_key" {
  key_name   = var.global_prefix
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "cert.pem"
}

resource "null_resource" "private_key_permissions" {
  depends_on = [local_file.private_key]
  provisioner "local-exec" {
    command     = "chmod 600 cert.pem"
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}

################################################################################
# IAM
################################################################################
resource "aws_iam_role" "kafka_consumer_role" {
  name = "kafka-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "kafka_consumer_policy" {
  name   = "kafka-consumer-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kafka:Consume",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kafka_consumer_policy_attachment" {
  role       = aws_iam_role.kafka_consumer_role.name
  policy_arn = aws_iam_policy.kafka_consumer_policy.arn
}

resource "aws_iam_instance_profile" "kafka_consumer_profile" {
  name = "kafka-consumer-profile"
  role = aws_iam_role.kafka_consumer_role.name
}

################################################################################
# Client Machine (EC2)
################################################################################

resource "aws_instance" "bastion_host" {
  depends_on             = [aws_msk_cluster.kafka]
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.private_key.key_name
  subnet_id              = aws_subnet.bastion_host_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_host.id]
  user_data = templatefile("bastion.tftpl", {
    bootstrap_server_1 = split(",", aws_msk_cluster.kafka.bootstrap_brokers)[0]
    bootstrap_server_2 = split(",", aws_msk_cluster.kafka.bootstrap_brokers)[1]
    bootstrap_server_3 = split(",", aws_msk_cluster.kafka.bootstrap_brokers)[2]
  })
  tags = {
    Name = "${var.global_prefix}-BastionHostInstance"
  }
  root_block_device {
    volume_type = "gp2"
    volume_size = 45
  }
}

################################################################################
# S3
################################################################################

resource "aws_s3_bucket" "json_data_bucket" {
  bucket = "${var.global_prefix}-json-data-bucket"

  tags = {
    Name = "KafkaJsonDataBucket"
  }
}

################################################################################
# Data Producer Machine (EC2)
################################################################################

resource "aws_instance" "data_producer" {
  depends_on = [aws_msk_cluster.kafka] # , aws_s3_object.kafka_package, aws_s3_object.data_producer_script
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.private_key.key_name
  subnet_id              = aws_subnet.ec2_data_producer_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_data_producer.id]
  # Use templatefile to inject variables into user data
  user_data = templatefile("data_producer_user_data.sh", {
    GITHUB_REPO_URL    = "https://github.com/mohamed06H/flight-data-pipeline.git"
    CLONE_DIR          = "/home/ec2-user/flight-data-pipeline"
    BOOTSTRAP_SERVERS  = aws_msk_cluster.kafka.bootstrap_brokers
    SECURITY_PROTOCOL  = aws_msk_cluster.kafka.encryption_info[0].encryption_in_transit[0].client_broker
    SKYSCANNER_API_KEY = var.SKYSCANNER_API_KEY
    TOPIC_NAME = var.TOPIC_NAME
  })

  # iam_instance_profile   = aws_iam_instance_profile.data_producer_instance_profile.name

  tags = {
    Name = "${var.global_prefix}-DataProducerInstance"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 45
  }

}

################################################################################
# Data Consumer Machine (EC2)
################################################################################
resource "aws_instance" "kafka_consumer" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.private_key.key_name
  subnet_id              = aws_subnet.kafka_consumer_subnet.id
  vpc_security_group_ids = [aws_security_group.kafka_consumer_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.kafka_consumer_profile.name

  user_data = templatefile("kafka_consumer_user_data.sh", {
    GITHUB_REPO_URL    = "https://github.com/mohamed06H/flight-data-pipeline.git"
    CLONE_DIR          = "/home/ec2-user/kafka-consumer"
    BOOTSTRAP_SERVERS = aws_msk_cluster.kafka.bootstrap_brokers
    SECURITY_PROTOCOL = aws_msk_cluster.kafka.encryption_info[0].encryption_in_transit[0].client_broker
    TOPIC_NAME       = var.TOPIC_NAME
    S3_BUCKET_NAME    = aws_s3_bucket.json_data_bucket.bucket
  })

  tags = {
    Name = "${var.global_prefix}-KafkaConsumerInstance"
  }
}
