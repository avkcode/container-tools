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

## Rational
When building containerized environments using standard Dockerfiles, each customization layer creates:
- Storage bloat - Every RUN apt-get install creates a new layer, wasting disk space with duplicate dependencies
- Network inefficiency - Redundant package downloads occur across different images
- Slow iterations - Rebuilding images requires repeating all previous steps

With this tool one can build:
- Minimal base images from scratch using debootstrap
- Precisely including only required components in the initial build
- Creating specialized variants (Java, Kafka, etc.) from common foundations

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
Artifact location: debian/dist/debian11-graal-slim/debian11-graal-slim.tar
Artifact size: 124M
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Image was built successfully!
Artifact location: debian/dist/debian11-graal-slim/debian11-graal-slim.tar
To load and run this Docker image, follow these steps:
Load the Docker image from the .tar file:
   cat debian/dist/debian11-graal-slim/debian11-graal-slim.tar | docker import - debian/dist/debian11-graal-slim/debian11-graal-slim
Verify the image was loaded successfully:
   docker images
Run the Docker container:
   docker run -it <IMAGE_NAME>
   Replace <IMAGE_NAME> with the name of the image loaded in the first step.
Example:
   docker run -it debian/dist/debian11-graal-slim/debian11-graal-slim /bin/bash
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Time elapsed: 193
```

## How to extend
1. Add recipe to recipes/
2. Make sure that the link to artifact and SHA256 is correct (e.g `sha256sum kafka_2.13-4.0.0.tgz`):
```bash
KAFKA_VERSION='4.0.0'
KAFKA_SHA='7b852e938bc09de10cd96eca3755258c7d25fb89dbdd76305717607e1835e2aa'
KAFKA_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz"
```
3. Add target to the Makefile
```makefile
debian11-java-slim-kafka:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(RECIPES)/kafka/kafka.sh \
			--scripts=$(SCRIPTS)/security-scan.sh
```
Profit

---
## Bootstrapping

[firecracker-sandbox](https://github.com/avkcode/firecracker-sandbox) is a complimentary project. Can you use for clean room bootstrapping:
1. git clone https://github.com/avkcode/firecracker-sandbox.git

Firecracker requires bootable rootfs image and Linux Kernel. To create rootfs and download prebuilt Kernel execute `create-debian-rootfs.sh`script:

```shell
bash tools/create-debian-rootfs.sh
```

It should produce `firecracker-rootfs.ext4` and `vmlinux` files. `vm-config.json` is used for VM boot options.

If you want to compile custom Kernel use tools\download-and-build-kernel.sh script.

2. Set Up Networking
```bash
make net-up
```
This creates a `tap0` device, assigns an IP address, enables IP forwarding, and sets up NAT.

3. Activate the Firecracker API Socket
```bash
make activate
```
This creates the Firecracker API socket at `/tmp/firecracker.socket`.

4. Start the MicroVM
```bash
make up
```
Starts the Firecracker MicroVM using the configuration in `vm-config.json`.

default password & username is `root`

5. Install dependencies:
```bash
apt-get install docker.io git make debootstrap sudo unzip curl
```

6. git clone https://github.com/avkcode/container-tools.git

---
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
