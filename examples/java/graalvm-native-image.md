# Building GraalVM Native Images

This example demonstrates how to use Container Tools to build and deploy GraalVM native images for Java applications.

## Prerequisites

- Container Tools installed
- Java application source code
- Basic understanding of GraalVM native image compilation

## What are GraalVM Native Images?

GraalVM native images are ahead-of-time compiled Java applications that:
- Start significantly faster than traditional JVM applications
- Use less memory
- Can be packaged as standalone executables
- Don't require a JVM at runtime

## Steps to Build a Native Image

### 1. Build the GraalVM base image

```bash
make debian11-graal
```

### 2. Load the image into Docker

```bash
cat dist/debian11-graal/debian11-graal.tar | docker import - debian11-graal:latest
```

### 3. Create a Dockerfile for building your native image

```dockerfile
FROM debian11-graal:latest AS builder

# Install necessary packages
RUN apt-get update && apt-get install -y build-essential libz-dev

# Set up GraalVM native image
RUN gu install native-image

# Copy your application
WORKDIR /app
COPY . /app/

# Build the application and create a native image
RUN ./mvnw clean package
RUN native-image -jar target/my-application.jar

# Create a minimal runtime image
FROM debian11:latest
COPY --from=builder /app/my-application /app/my-application
ENTRYPOINT ["/app/my-application"]
```

### 4. Build and run your native image container

```bash
docker build -t my-native-app:1.0 .
docker run -p 8080:8080 my-native-app:1.0
```

## Example: Spring Boot Native Image

For a Spring Boot application with native image support:

```dockerfile
FROM debian11-graal:latest AS builder

RUN apt-get update && apt-get install -y build-essential libz-dev

WORKDIR /app
COPY . /app/

# Build with Spring Boot's native image support
RUN ./mvnw -Pnative native:compile

# Create minimal runtime image
FROM debian11:latest
COPY --from=builder /app/target/my-application /app/my-application
ENTRYPOINT ["/app/my-application"]
```

## Performance Considerations

- Native image compilation can be memory-intensive; ensure your build environment has sufficient resources
- Some Java features like reflection require special configuration for native images
- Create a `reflect-config.json` file for classes that use reflection
- Use the `-H:+ReportExceptionStackTraces` flag to get better error information

## Troubleshooting

- If native image compilation fails, check GraalVM compatibility with your libraries
- For "Class not found" errors at runtime, ensure all required classes are included in the native image configuration
- Memory issues during compilation can be addressed by increasing the build container's memory allocation
