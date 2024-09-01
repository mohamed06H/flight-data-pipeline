from confluent_kafka import Consumer, KafkaError
import boto3
import json
import sys
from datetime import datetime

# Read Kafka configuration and API KEY from command-line arguments
if len(sys.argv) < 5:
    print("- Usage: python data_producer.py <BOOTSTRAP_SERVERS> <SECURITY_PROTOCOL> <TOPIC_NAME> <S3_BUCKET_NAME>")
    sys.exit(1)

bootstrap_servers = sys.argv[1]
security_protocol = sys.argv[2]
kafka_topic = sys.argv[3]
s3_bucket = sys.argv[4]

# Kafka configuration
kafka_config = {
    'bootstrap.servers': bootstrap_servers,
    'group.id': 's3-consumer-group',
    'auto.offset.reset': 'earliest',
    'security.protocol': security_protocol
}

# Initialize Kafka consumer
consumer = Consumer(kafka_config)

# Subscribe to the Kafka topic
consumer.subscribe([kafka_topic])

# S3 configuration
s3_client = boto3.client('s3')


def write_to_s3(json_data, key):
    try:
        response = s3_client.put_object(
            Bucket=s3_bucket,
            Key=key,
            Body=json.dumps(json_data),
            ContentType='application/json'
        )
        print(f'Successfully wrote to S3: {key}')
    except Exception as e:
        print(f'Failed to write to S3: {str(e)}')


try:
    while True:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                print(msg.error())
                break

        # Process the message
        json_message = json.loads(msg.value().decode('utf-8'))

        # Generate S3 object key (filename) with partitioned path
        now = datetime.utcnow()
        s3_key = f"year={now.year}/month={now.month:02}/day={now.day:02}/data_{now.strftime('%H%M%S%f')}.json"

        # Write the JSON message to S3
        write_to_s3(json_message, s3_key)

except KeyboardInterrupt:
    pass
finally:
    # Close down consumer gracefully
    consumer.close()
