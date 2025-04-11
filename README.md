# Container Tools

<table>
  <tr>
    <td valign="top" width="100">
      <img src="https://raw.githubusercontent.com/avkcode/container-tools/refs/heads/main/favicon.svg"
           alt="Container Tools"
           width="80">
    </td>
    <td valign="middle">
      Container Tools is a project that provides scripts and utilities to automate the creation of minimal Debian-based root filesystems (rootfs) using debootstrap. It supports customization with specific packages, configurations, and integrates security scanning for containerized environments. Can be easily extend for other distros and projects.
    </td>
  </tr>
</table>

## How it works:
```
Usage: make <target>
 ============================
  ** Debian Linux targets **
 ============================
|all|
|debian11|
|debian11-java|
|debian11-java-slim|
|debian11-corretto|
|debian11-graal|
|debian11-graal-slim|
|debian11-java-slim-maven|
|debian11-java-slim-gradle|
|debian11-graal-slim-maven|
|debian11-graal-slim-gradle|
|debian11-java-kafka|
|debian11-java-slim-kafka|
```

## In the end it will produce the image
```
[Image was built successfully]
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Artifact location: debian/dist/debian11-java-slim-kafka/debian11-java-slim-kafka.tar

Artifact size: 228M

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Image was built successfully!
Artifact location: debian/dist/debian11-java-slim-kafka/debian11-java-slim-kafka.tar

To load and run this Docker image, follow these steps:

Load the Docker image from the .tar file:
   cat debian/dist/debian11-java-slim-kafka/debian11-java-slim-kafka.tar | docker import - debian/dist/debian11-java-slim-kafka/debian11-java-slim-kafka

Verify the image was loaded successfully:
   docker images

Run the Docker container:
   docker run -it <IMAGE_NAME>
   Replace <IMAGE_NAME> with the name of the image loaded in the first step.

Example:
   docker run -it debian/dist/debian11-java-slim-kafka/debian11-java-slim-kafka /bin/bash
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Time elapsed: 182
```

## Repository Directory Structure

### Root Directory
- `Dockerfile` - Docker configuration for building the environment
- `Makefile` - Build automation with targets for different images
- `README.md` - Project documentation and usage instructions
- `tools.mk` - Makefile tools and utilities
- `Vagrantfile` - Vagrant configuration for development environment

### debian/
Contains Debian-specific files for image building

#### debian/debootstrap/
Configuration files for different Debian versions:
- `buster` - Debian 10 (Buster) config
- `bullseye` - Debian 11 (Bullseye) config  
- `jessie` - Debian 8 (Jessie) config
- `stretch` - Debian 9 (Stretch) config
- `unstable` - Debian Unstable config
- `wheezy` - Debian 7 (Wheezy) config

#### debian/keys/
GPG keys for package verification:
- `buster.gpg` - Key for Debian Buster
- `unstable.gpg` - Key for Debian Unstable

#### Key Files:
- `mkimage.sh` - Main script for building Debian root filesystems

### recipes/
Contains installation scripts for different components

#### recipes/java/
Java-related installation scripts:
- `java.sh` - Full JDK installation
- `java_slim.sh` - Slimmed-down JDK installation  
- `graalvm.sh` - GraalVM installation
- `graalvm_slim.sh` - Slim GraalVM installation
- `corretto.sh` - Amazon Corretto JDK
- `maven.sh` - Apache Maven
- `gradle.sh` - Gradle build tool

#### recipes/kafka/
- `kafka.sh` - Apache Kafka installation (added in our solution)

### scripts/
Post-build maintenance scripts:
- `security-scan.sh` - Runs Trivy security scanner

### dist/
Output directory (created during build):
- Contains final built images in `.tar` format
- Organized by image name (e.g., `debian11-java-slim/`)

### download/
Temporary download directory (created during build):
- Stores downloaded packages and binaries
