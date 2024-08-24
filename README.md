# Infrastructure as Code with Terraform

We will deploy a Kafka Cluster in [Amazon MSK](https://aws.amazon.com/msk/), Managed Streaming for Apache Kafka,
using terraform.


## Pre-requisites

- [Terraform](https://www.terraform.io/downloads.html)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)


## Getting Started - Overview of resources

The variable `global_prefix` is used to prefix all the resources that will be created. This is useful if you want to fastly 
identified the resources created for this specific use case.

You can change the value of this variable in the `variables.tf` file.

We are also customizing our Kafka Cluster options. This means we will change the parameters that are going to be written
into the `server.properties` file of each broker of the cluster. This can be found under the 
`resource "aws_msk_configuration" "kafka_config" in the serfver_properties field`. Basically we are telling with the 
configuration provided that we want to enable automatic topic creation in the Kafka cluster. 
This means that whenever developers write and read data from topics, they will be created automatically in the cluster.
Similarly, we are enabling the deletion of topics, so the cluster won't reject any commands issued to delete topics.

Having these configurations are great because it allows you to have better control of your clusters, 
as they are managed separately from the cluster. You can share the same configuration with different Kafka clusters, 
or have each cluster with their own configuration.

Based on `resource "aws_msk_cluster" "kafka"`, our cluster will have 3 nodes, each one using the kafka.m5.large instance type.
We configured each broker to use an AWS EBS volume, with one terabyte of capacity.
This cluster will run in private subnets and use a custom security group.
Encryption in transit and at rest was enabled. For at rest, we used the custom KMS key.


## Networking

This cluster will run in private subnets. This is important because Kafka is a persistent layer for applications and 
microservices; and just like you would do with any other data store, it is a best practice to isolate the resource in 
private subnets. For this reason, you will need to create three subnets in a given VPC, associate a valid CIDR block 
for each, and map them to availability zones.

Finally, you need to create a security group for the Kafka cluster. This is required because you want to allow ingress 
traffic to the cluster over the exposed port `9092`, and this traffic needs to be enabled for all private subnets.

Monitoring using CloudWatch is also configured in this deployment.

## Deploying the infrastructure

Locate yourself under the `terraform` directory and run the following commands:

```bash
aws configure  # enter your AWS credentials

terraform init
terraform plan  # this is optional, it will show you what will be deployed - check that 23 resources will be created
terraform apply
```

It will take around `35 minutes` to complete the deployment. You will see the following output:

```bash
Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

execute_this_to_access_the_bastion_host = "ssh ec2-user@x.xxx.xxx.xxx -i cert.pem"
```

You probably have noticed as well a new file under your terraform folder, `cert.pem`. This is the private key that you need
to use to access the bastion host. You can use the command provided in the output to access the bastion host.


Now, check on your AWS Account that everything has been created. Connect to you EC2 instance with the output command.

## Testing the Kafka Cluster

Once you are connected to the bastion host, you can test the Kafka cluster by running the following commands:

```bash
# Check your bootstrap servers
more bootstrap-servers

# Create a topic
kafka-topics.sh --bootstrap-server <your-bootstrap-server> --create --topic test --partitions 6 --replication-factor 3

# Check the correct creation of your topic
kafka-topics.sh --list --bootstrap-server <your-bootstrap-server>
```

You can use the same commands we have been using in class sections to produce and consume messages from the topic.

## Destroying the infrastructure

Once you are done with the testing, you can destroy the infrastructure by running the following command:

```bash
terraform destroy
```

*Remember to always be under the `terraform` directory when running terraform commands.*
