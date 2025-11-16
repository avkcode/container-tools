# Deploying NodeJS Web Applications

This example demonstrates how to use Container Tools to deploy NodeJS web applications.

## Prerequisites

- Container Tools installed
- NodeJS application source code
- Basic understanding of NodeJS applications

## Steps to Deploy a NodeJS Application

### 1. Build the NodeJS base image

```bash
make debian11-nodejs
```

This creates a minimal Debian-based image with NodeJS installed.

### 2. Load the image into Docker

```bash
cat dist/debian11-nodejs/debian11-nodejs.tar | docker import - debian11-nodejs:latest
```

### 3. Create a Dockerfile for your NodeJS application

```dockerfile
FROM debian11-nodejs:latest

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["node", "app.js"]
```

### 4. Build and run your NodeJS application container

```bash
docker build -t my-nodejs-app:1.0 .
docker run -p 3000:3000 my-nodejs-app:1.0
```

## Example: Express.js Application

For an Express.js application:

```dockerfile
FROM debian11-nodejs:latest

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Add health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1

# Expose the application port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Start the application
CMD ["node", "server.js"]
```

## Production Best Practices

1. **Use a non-root user**:
   ```dockerfile
   RUN groupadd -r nodejs && useradd -r -g nodejs nodejs
   USER nodejs
   ```

2. **Multi-stage builds for smaller images**:
   ```dockerfile
   FROM debian11-nodejs:latest AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build

   FROM debian11-nodejs:latest
   WORKDIR /app
   COPY --from=builder /app/dist /app
   COPY package*.json ./
   RUN npm ci --only=production
   CMD ["node", "server.js"]
   ```

3. **Set NODE_ENV to production**:
   ```dockerfile
   ENV NODE_ENV=production
   ```

## Troubleshooting

- If you encounter "node not found" errors, check the PATH environment variable
- For dependency issues, ensure your package.json and package-lock.json are correctly copied
- Memory issues can be addressed by setting the NODE_OPTIONS environment variable:
  ```dockerfile
  ENV NODE_OPTIONS="--max-old-space-size=2048"
  ```
