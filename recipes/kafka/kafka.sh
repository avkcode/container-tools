#!/usr/bin/env bash

KAFKA_VERSION='4.0.0'
KAFKA_SHA='7b852e938bc09de10cd96eca3755258c7d25fb89dbdd76305717607e1835e2aa'
KAFKA_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz"

kafka() {
    # Check if Java is installed (required for Kafka)
    if [[ ! -d "$target/opt/jdk" && ! -d "$target/opt/graal" ]]; then
        error 1 JAVA_REQUIRED "Kafka requires Java to be installed. Please include a Java recipe first."
    fi

    # Download Kafka
    if [[ ! -f ${DOWNLOAD}/kafka-${KAFKA_VERSION}.tgz ]]; then
        download ${KAFKA_URL} kafka-${KAFKA_VERSION}.tgz ${DOWNLOAD}
    fi

    # Verify checksum
    check_sum ${KAFKA_SHA} ${DOWNLOAD}/kafka-${KAFKA_VERSION}.tgz

    # Install Kafka
    run mkdir --parents "$target"/opt/kafka
    run tar -xzf ${DOWNLOAD}/kafka-${KAFKA_VERSION}.tgz --strip-components=1 --directory "$target"/opt/kafka

    # Create directories for Kafka data
    run mkdir --parents "$target"/var/lib/kafka/data
    run mkdir --parents "$target"/var/log/kafka

    # Configure Kafka environment
    echo -e '\n### KAFKA ###' >> "$target"/root/.bashrc
    echo 'export KAFKA_HOME=/opt/kafka' >> "$target"/root/.bashrc
    echo 'export PATH=$PATH:$KAFKA_HOME/bin' >> "$target"/root/.bashrc

    # Create a basic Kafka configuration file
    cat > "$target"/opt/kafka/config/server.properties <<EOF
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The id of the broker. This must be set to a unique integer for each broker.
broker.id=0

# The address the socket server listens on. It will get the value returned from
# java.net.InetAddress.getCanonicalHostName() if not configured.
#   FORMAT:
#     listeners = listener_name://host_name:port
#   EXAMPLE:
#     listeners = PLAINTEXT://your.host.name:9092
listeners=PLAINTEXT://:9092

# Hostname and port the broker will advertise to producers and consumers. If not set,
# it uses the value for "listeners" if configured.  Otherwise, it will use the value
# returned from java.net.InetAddress.getCanonicalHostName().
advertised.listeners=PLAINTEXT://localhost:9092

# The number of threads that the server uses for receiving requests from the network and sending responses to the network
num.network.threads=3

# The number of threads that the server uses for processing requests, which may include disk I/O
num.io.threads=8

# The send buffer (SO_SNDBUF) used by the socket server
socket.send.buffer.bytes=102400

# The receive buffer (SO_RCVBUF) used by the socket server
socket.receive.buffer.bytes=102400

# The maximum size of a request that the socket server will accept (protection against OOM)
socket.request.max.bytes=104857600

# A comma separated list of directories under which to store log files
log.dirs=/var/lib/kafka/data

# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
num.partitions=1

# The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
# This value is recommended to be increased for installations with data dirs located in RAID array.
num.recovery.threads.per.data.dir=1

# The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"
# For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1

# Log retention settings
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# Zookeeper connection string (see zookeeper docs for details).
# This is a comma separated host:port pairs, each corresponding to a zk
# server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".
# You can also append an optional chroot string to the urls to specify the
# root directory for all kafka znodes.
zookeeper.connect=localhost:2181

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=18000

# Enable topic deletion
delete.topic.enable=true

# Log configuration
log4j.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%d] %p %m (%c)%n
EOF

    # Create a simple startup script
    cat > "$target"/opt/kafka/bin/start-kafka.sh <<EOF
#!/usr/bin/env bash

# Start Zookeeper (included with Kafka)
echo "Starting Zookeeper..."
/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties

# Start Kafka
echo "Starting Kafka..."
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties

# Wait for Kafka to start
sleep 5

# Create a test topic if it doesn't exist
/opt/kafka/bin/kafka-topics.sh --create --if-not-exists \
    --bootstrap-server localhost:9092 \
    --replication-factor 1 \
    --partitions 1 \
    --topic test-topic

echo "Kafka is running. Use 'kafka-console-producer.sh' and 'kafka-console-consumer.sh' to test."
EOF

    chmod +x "$target"/opt/kafka/bin/start-kafka.sh

    # Create a systemd service file if systemd is present
    if [[ -d "$target"/etc/systemd ]]; then
        cat > "$target"/etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target
After=network.target

[Service]
Type=simple
Environment="JAVA_HOME=/opt/jdk"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
    fi

    # Clean up
    run rm --recursive --force "$target"/opt/kafka/bin/windows
    run rm --recursive --force "$target"/opt/kafka/site-docs
}
