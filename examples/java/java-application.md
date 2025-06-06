# Containerizing Java Applications

This example demonstrates how to containerize Java applications using the Container Tools Java images.

## Prerequisites

- Container Tools installed
- Java application source code or JAR file
- Basic understanding of Java applications

## Java Image Variants

Container Tools provides several Java image variants:

- `debian11-java`: Full JDK with development tools
- `debian11-java-slim`: Minimal JRE for running applications
- `debian11-corretto`: Amazon Corretto JDK
- `debian11-graal`: GraalVM for improved performance
- `debian11-graal-slim`: Minimal GraalVM runtime

## Steps to Containerize a Java Application

### 1. Build a Java base image

Choose the appropriate Java variant for your needs:

```bash
# For a standard Java environment
make debian11-java-slim

# For GraalVM
make debian11-graal-slim

# For Amazon Corretto
make debian11-corretto
```

### 2. Load the image into Docker

```bash
cat dist/debian11-java-slim/debian11-java-slim.tar | docker import - debian11-java-slim:latest
```

### 3. Create a Dockerfile for your application

```dockerfile
FROM debian11-java-slim:latest

# Set working directory
WORKDIR /app

# Copy your JAR file
COPY target/my-application.jar /app/

# Set the entrypoint
ENTRYPOINT ["java", "-jar", "my-application.jar"]
```

### 4. Build and run your application container

```bash
docker build -t my-java-app:1.0 .
docker run -p 8080:8080 my-java-app:1.0
```

## Example: Spring Boot Application

For a Spring Boot application:

```dockerfile
FROM debian11-java-slim:latest

WORKDIR /app

COPY target/spring-boot-app.jar /app/app.jar

# Add health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Expose the application port
EXPOSE 8080

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
```

## Using Build Tools

Container Tools also provides images with Maven and Gradle pre-installed:

```bash
# For Maven
make debian11-java-slim-maven

# For Gradle
make debian11-java-slim-gradle
```

These images can be used for building Java applications within containers.

## Troubleshooting

- If you encounter "java not found" errors, ensure the correct Java path is set
- For memory issues, adjust the JVM heap settings with `-Xmx` and `-Xms` flags
- Check Java version compatibility with your application
