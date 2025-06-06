# Setting Up a Kafka Cluster

This example demonstrates how to use Container Tools to set up a Kafka cluster.

## Prerequisites

- Container Tools installed
- Basic understanding of Apache Kafka
- Docker and Docker Compose installed

## Steps to Set Up a Kafka Cluster

### 1. Build the Kafka base image

```bash
make debian11-java-slim-kafka
```

This creates a minimal Debian-based image with Java and Kafka installed.

### 2. Load the image into Docker

```bash
cat dist/debian11-java-slim-kafka/debian11-java-slim-kafka.tar | docker import - kafka:latest
```

### 3. Create a Docker Compose file for your Kafka cluster

Create a file named `docker-compose.yml`:

```yaml
version: '3'
services:
  zookeeper:
    image: kafka:latest
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    command: /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
    volumes:
      - ./zookeeper-data:/var/lib/zookeeper/data

  kafka1:
    image: kafka:latest
    hostname: kafka1
    container_name: kafka1
    ports:
      - "9092:9092"
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka1:9092
      - KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092
    command: /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
    volumes:
      - ./kafka1-data:/var/lib/kafka/data
    depends_on:
      - zookeeper

  kafka2:
    image: kafka:latest
    hostname: kafka2
    container_name: kafka2
    ports:
      - "9093:9092"
    environment:
      - KAFKA_BROKER_ID=2
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka2:9092
      - KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092
    command: /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
    volumes:
      - ./kafka2-data:/var/lib/kafka/data
    depends_on:
      - zookeeper

  kafka3:
    image: kafka:latest
    hostname: kafka3
    container_name: kafka3
    ports:
      - "9094:9092"
    environment:
      - KAFKA_BROKER_ID=3
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka3:9092
      - KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092
    command: /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
    volumes:
      - ./kafka3-data:/var/lib/kafka/data
    depends_on:
      - zookeeper
```

### 4. Start the Kafka cluster

```bash
docker-compose up -d
```

### 5. Verify the cluster is running

```bash
docker-compose ps
```

### 6. Create a test topic

```bash
docker exec -it kafka1 /opt/kafka/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server kafka1:9092 --replication-factor 3 --partitions 3
```

### 7. List topics

```bash
docker exec -it kafka1 /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka1:9092
```

## Kafka Configuration Options

You can customize your Kafka deployment by modifying these environment variables:

- `KAFKA_BROKER_ID`: Unique ID for each Kafka broker
- `KAFKA_ZOOKEEPER_CONNECT`: ZooKeeper connection string
- `KAFKA_ADVERTISED_LISTENERS`: Listeners advertised to clients
- `KAFKA_LISTENERS`: Socket server listeners
- `KAFKA_LOG_RETENTION_HOURS`: How long to keep logs (default: 168 hours/7 days)
- `KAFKA_LOG_SEGMENT_BYTES`: The maximum size of a log segment file (default: 1GB)
- `KAFKA_NUM_PARTITIONS`: Default number of log partitions per topic (default: 1)

## Troubleshooting

- If brokers can't connect to each other, check network settings and advertised listeners
- For ZooKeeper connection issues, ensure ZooKeeper is running and accessible
- Check logs with `docker-compose logs zookeeper` or `docker-compose logs kafka1`
