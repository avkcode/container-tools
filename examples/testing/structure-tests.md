# Container Structure Testing

This example demonstrates how to use container-structure-test to validate your container images.

## Prerequisites

- Container Tools installed
- container-structure-test installed
- Docker installed

## Installing container-structure-test

```bash
curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
chmod +x container-structure-test-linux-amd64
sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
```

## Creating Test Configuration

Create a YAML file (e.g., `debian11-test.yaml`) with your test specifications:

```yaml
schemaVersion: '2.0.0'

# File existence tests
fileExistenceTests:
  - name: 'Root filesystem'
    path: '/'
    shouldExist: true
    permissions: 'drwxr-xr-x'
  
  - name: 'Bash exists'
    path: '/bin/bash'
    shouldExist: true
    permissions: '-rwxr-xr-x'

# File content tests
fileContentTests:
  - name: 'Check OS release'
    path: '/etc/os-release'
    expectedContents: ['Debian GNU/Linux 11 (bullseye)']
    
  - name: 'Check hosts file'
    path: '/etc/hosts'
    expectedContents: ['127.0.0.1\\s+localhost']

# Command tests
commandTests:
  - name: 'Check bash version'
    command: 'bash'
    args: ['--version']
    expectedOutput: ['GNU bash, version']
    
  - name: 'Check apt is working'
    command: 'apt-get'
    args: ['update']
    exitCode: 0

# Metadata tests
metadataTest:
  env:
    - key: 'PATH'
      value: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  workdir: '/'
```

## Running Tests

### 1. Build and load your image

```bash
make debian11
cat dist/debian11/debian11.tar | docker import - debian11:latest
```

### 2. Run the test using the script

```bash
./scripts/test.py --image debian11:latest --config debian11-test.yaml
```

### 3. Run tests directly with container-structure-test

```bash
container-structure-test test --image debian11:latest --config debian11-test.yaml
```

## Example Test Configurations

### Java Image Test

```yaml
schemaVersion: '2.0.0'

commandTests:
  - name: 'Java version'
    command: 'java'
    args: ['-version']
    expectedError: ['openjdk version "11']
    
  - name: 'Java compiler'
    command: 'javac'
    args: ['-version']
    expectedOutput: ['javac 11']

fileExistenceTests:
  - name: 'Java home'
    path: '/usr/lib/jvm'
    shouldExist: true
```

### NodeJS Image Test

```yaml
schemaVersion: '2.0.0'

commandTests:
  - name: 'Node.js version'
    command: 'node'
    args: ['-v']
    expectedOutput: ['v16']
    
  - name: 'NPM version'
    command: 'npm'
    args: ['-v']
    expectedOutput: ['8']

fileExistenceTests:
  - name: 'Node executable'
    path: '/usr/bin/node'
    shouldExist: true
```

## Integrating with CI/CD

Example GitHub Actions workflow:

```yaml
name: Container Structure Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      
      - name: Install container-structure-test
        run: |
          curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
          chmod +x container-structure-test-linux-amd64
          sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
      
      - name: Build container image
        run: make debian11-java-slim
      
      - name: Import image
        run: cat dist/debian11-java-slim/debian11-java-slim.tar | docker import - debian11-java-slim:test
      
      - name: Run structure tests
        run: container-structure-test test --image debian11-java-slim:test --config test/debian11-java-slim.yaml
```

## Troubleshooting

- If tests fail, check the exact output format against your expected values
- For permission tests, ensure you're using the correct permission format
- Regular expressions can be used in expectedOutput/expectedError for more flexible matching
