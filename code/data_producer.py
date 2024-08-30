import sys
import http.client
import urllib.parse
import json
from datetime import datetime
from confluent_kafka import Producer


# Read Kafka configuration and API KEY from command-line arguments
if len(sys.argv) < 4:
    print("- Usage: python data_producer.py <BOOTSTRAP_SERVERS> <SECURITY_PROTOCOL> <SKYSCANNER_API_KEY>")
    sys.exit(1)

bootstrap_servers = sys.argv[1]
security_protocol = sys.argv[2]
SKYSCANNER_API_KEY = sys.argv[3]

# API configuration
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
market = "en-US"
countryCode = "US"


# Function to request data from API
def request_data():
    conn = http.client.HTTPSConnection(API_URL)

    headers = {
        'x-rapidapi-key': SKYSCANNER_API_KEY,
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

    conn.request(method="GET", url=url, headers=headers)

    res = conn.getresponse()
    data = res.read()
    if data == 'b{}':
        data = json.dumps({"empty_response": True})
        print("-- Empty response from API please check your subscription plan", datetime.now())
    elif data is not None:
        print("-- Data is read successfully from API ", datetime.now())
    else:
        print("Data is None !")
        data = json.dumps({"None response": True})

    # Close the connection
    conn.close()

    return data


# Kafka configuration
kafka_config = {
    'bootstrap.servers': bootstrap_servers,
    'client.id': 'data-producer-client',
    'security.protocol': security_protocol,
    'message.max.bytes': 5242880  # 5 MB
}
kafka_topic = 'flight-kafka-topic'

# Create a Kafka producer instance
producer = Producer(kafka_config)


# Function to send message to Kafka
def send_to_kafka(topic, message):
    producer.produce(topic, value=message)
    producer.flush()


# Request data from API
#data = request_data()
# DEBUG
parsed_data = {"Time": datetime.now()}

# Convert parsed data back to JSON string for Kafka
json_message = json.dumps(parsed_data)

# Send the response to the Kafka topic
send_to_kafka(kafka_topic, json_message)

print(f"--- Sent message to Kafka topic '{kafka_topic}'")
