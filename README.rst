Container Tools
=============

.. image:: https://raw.githubusercontent.com/avkcode/container-tools/refs/heads/main/favicon.svg
   :alt: Container Tools Logo
   :width: 80px
   :align: right

Container Tools provides scripts and utilities to automate the creation of minimal Debian-based root filesystems (rootfs) using debootstrap. It supports customization with specific packages, configurations, and integrates security scanning for containerized environments. Easily extensible for other distros and projects.

Rationale
--------

Traditional Dockerfile-based builds suffer from several inefficiencies:

- **Storage bloat**: Each ``RUN apt-get install`` creates a new layer, wasting disk space with duplicate dependencies
- **Network inefficiency**: Redundant package downloads across different images
- **Slow iterations**: Rebuilding images requires repeating all previous steps

This tool enables you to:

- Build minimal base images from scratch using debootstrap
- Precisely include only required components in the initial build
- Create specialized variants (Java, Kafka, etc.) from common foundations

Features
--------

- Lightweight Debian-based rootfs generation
- Customizable package selection
- Security scanning integration (Trivy)
- Support for Java variants (Standard, GraalVM, Corretto)
- Build tool integration (Maven, Gradle)
- Apache Kafka support
- Clean room build capability via Firecracker sandbox

Quick Start
-----------

Prerequisites
~~~~~~~~~~~~~

- Linux system (or VM)
- Docker
- debootstrap
- make
- curl, unzip, sudo

Building Images
~~~~~~~~~~~~~~

.. code-block:: bash

   git clone https://github.com/avkcode/container-tools.git
   cd container-tools
   make debian11-java-slim  # Example target

Available targets:

::

   debian11
   debian11-java
   debian11-java-slim
   debian11-corretto
   debian11-graal
   debian11-graal-slim
   debian11-java-slim-maven
   debian11-java-slim-gradle
   debian11-graal-slim-maven
   debian11-graal-slim-gradle
   debian11-java-kafka
   debian11-java-slim-kafka

Using Built Images
~~~~~~~~~~~~~~~~~

After successful build:

.. code-block:: bash

   # Load the image
   cat debian/dist/debian11-graal-slim/debian11-graal-slim.tar | docker import - debian11-graal-slim

   # Run the container
   docker run -it debian11-graal-slim /bin/bash

Extending the Tool
-----------------

To add new components:

1. Create a recipe in ``recipes/`` directory
2. Verify artifact URLs and SHA256 checksums
3. Add a new target to the Makefile

Example for adding NodeJS:

.. code-block:: makefile

debian11-nodejs:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \\
			--name=$@ \\
			--keyring=$(DEBIAN_KEYRING) \\
			--variant=container \\
			--release=stable \\
			--recipes=$(RECIPES)/nodejs/nodejs.sh \\
			--scripts=$(SCRIPTS)/security-scan.sh

Clean Room Building with Firecracker
-----------------------------------

For secure, isolated builds:

1. Set up Firecracker sandbox:

Firecracker requires bootable rootfs image and Linux Kernel. To create rootfs and download prebuilt Kernel execute `create-debian-rootfs.sh`script:
.. code-block:: bash

   git clone https://github.com/avkcode/firecracker-sandbox.git
   cd firecracker-sandbox
   bash tools/create-debian-rootfs.sh

It should produce `firecracker-rootfs.ext4` and `vmlinux` files. `vm-config.json` is used for VM boot options.
If you want to compile custom Kernel use tools\download-and-build-kernel.sh script.

2. Configure networking:

.. code-block:: bash

   make net-up
   make activate
   make up

3. Install dependencies in the VM:

.. code-block:: bash

   apt-get install docker.io git make debootstrap sudo unzip curl

4. Build your images as usual

Repository Structure
-------------------

::

   container-tools/
   ├── Dockerfile            # Docker environment configuration
   ├── Makefile             # Build automation
   ├── debian/
   │   ├── debootstrap/     # Debian version configs
   │   ├── keys/            # GPG keys for verification
   │   └── mkimage.sh       # Rootfs builder script
   ├── recipes/
   │   ├── java/            # Java variants
   │   └── kafka/           # Kafka installation
   ├── scripts/             # Maintenance scripts
   ├── dist/                # Output images
   └── download/            # Temporary downloads

Security
--------

All builds include automated security scanning via Trivy in the ``security-scan.sh`` script.

Contributing
------------

Contributions are welcome. Please submit issues or pull requests for:

- New distro support
- Additional package recipes
- Security improvements
- Documentation enhancements
