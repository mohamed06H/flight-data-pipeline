import os
import http.client
import urllib.parse
import json
import time
from datetime import datetime
from confluent_kafka import Producer

# API configuration
API_KEY = "689519fe9bmsh551d4b6d7753298p1ff659jsnc4d424b4632f"
API_URL = "sky-scrapper.p.rapidapi.com"
originSkyId = "LOND"
originEntityId = "27544008"
destinationSkyId = "NYCA"
destinationEntityId = "27537542"
date = "2024-09-10"
cabinClass = "economy"
adults = "1"
sortBy = "best"
currency = "USD"
market = "en - US"
countryCode = "US"


# Function to request data from API
def request_data():
    conn = http.client.HTTPSConnection(API_URL)

    headers = {
        'x-rapidapi-key': API_KEY,
        'x-rapidapi-host': API_URL
    }

    # Encode the query parameters
    params = {
        "originSkyId": originSkyId,
        "destinationSkyId": destinationSkyId,
        "originEntityId": originEntityId,
        "destinationEntityId": destinationEntityId,
        "date": date,
        "cabinClass": cabinClass,
        "adults": adults,
        "sortBy": sortBy,
        "currency": currency,
        "market": market,
        "countryCode": countryCode
    }

    # Encode the parameters into a query string
    query_string = urllib.parse.urlencode(params)

    # Construct the URL with the encoded query string
    url = f"/api/v2/flights/searchFlights?{query_string}"

    conn.request(method="GET",
                 url=url,
                 headers=headers)

    res = conn.getresponse()
    data = res.read()

    print(data.decode("utf-8"))

    # Close the connection
    conn.close()

    return data


# Retrieve Kafka configuration from environment variables
bootstrap_servers = os.environ.get('BOOTSTRAP_SERVERS')
security_protocol = os.environ.get('SECURITY_PROTOCOL', 'PLAINTEXT')  # Default to PLAINTEXT if not set

# Kafka configuration
kafka_config = {
    'bootstrap.servers': bootstrap_servers
    'client.id': 'data-producer-client',
    'security.protocol': security_protocol
}
kafka_topic = 'flight-kafka-topic'

# Create a Kafka producer instance
producer = Producer(kafka_config)


# Function to send message to Kafka
def send_to_kafka(topic, message):
    producer.produce(topic, value=message)
    producer.flush()


# Initialize request counter and date tracking
request_count = 0
current_date = datetime.now().date()

while True:
    # Check if the date has changed to reset the counter
    if datetime.now().date() != current_date:
        request_count = 0
        current_date = datetime.now().date()

    if request_count < 10:
        # Request data from API
        data = request_data()

        # Parse the response (if JSON)
        parsed_data = json.loads(data)

        # Convert parsed data back to JSON string for Kafka
        json_message = json.dumps(parsed_data)

        # Send the response to the Kafka topic
        send_to_kafka(kafka_topic, json_message)

        print(f"Sent message to Kafka topic '{kafka_topic}'")

        # Increment the request counter
        request_count += 1
    else:
        print("Request limit reached for the day. Waiting until tomorrow.")

    # Sleep for 1 minute
    time.sleep(60)
