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
- Clean room build via Firecracker sandbox

Quick Start
-----------

Prerequisites
~~~~~~~~~~~~~

- Linux system (or VM)
- Docker
- debootstrap
- make
- curl, unzip, sudo

Displaying Help
--------------

To view all available build targets and their descriptions, run:

.. code-block:: bash

    make help

This will display:
- All available image build targets (Debian, Java, GraalVM, etc.)
- Utility targets (clean, test, shellcheck)
- Dependency checking commands

For detailed information about a specific target, you can also view the Makefile directly.

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
   debian11-nodejs

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

Clean Room Building with Firecracker
-----------------------------------

For secure, isolated builds:

1. Set up Firecracker sandbox:

Visit the Firecracker sandbox repository at https://github.com/avkcode/firecracker-sandbox.

Firecracker requires bootable rootfs image and Linux Kernel. To create rootfs and download prebuilt Kernel execute ``create-debian-rootfs.sh`` script:

.. code-block:: bash

   git clone https://github.com/avkcode/firecracker-sandbox.git
   cd firecracker-sandbox
   bash tools/create-debian-rootfs.sh

It should produce ``firecracker-rootfs.ext4`` and ``vmlinux`` files. ``vm-config.json`` is used for VM boot options.
If you want to compile custom Kernel use ``tools\download-and-build-kernel.sh`` script.

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
   ├── Dockerfile           # Docker environment configuration
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

GPG
---

Sign .tar Files
To sign .tar files, provide the directory or file path along with your GPG key ID:

.. code-block:: bash

   ./scripts/gpg.py --directory /path/to/tar/files --gpg-key-id YOUR_KEY_ID

The script generates an ASCII-armored signature file (.asc) for each .tar file.
If a signature file already exists, the script prompts to overwrite it.

Verify .tar Files
To verify .tar files, use the --verify flag:

.. code-block:: bash

   ./scripts/gpg.py --directory /path/to/tar/files --verify

By default, the script looks for a .asc signature file with the same name as the .tar file.
To specify a custom signature file, use the --sig-file option:

.. code-block:: bash

   ./scripts/gpg.py --directory /path/to/file.tar --verify --sig-file /path/to/signature.asc


Cosign
------

Sign .tar files in a specific directory:

.. code-block:: bash

   ./cosign.py --directory=path/to/tar/files

Use a Private Key for Signing
Sign images using the private key generated earlier:

.. code-block:: bash

   ./cosign.py --directory=path/to/tar/files --key=cosign.key

Push Signed Images to a Registry
Push signed images to a container registry:

.. code-block:: bash

   ./cosign.py --directory=path/to/tar/files --registry=myregistry.com/myrepo

Perform a Dry Run
Simulate the signing process without executing commands:

.. code-block:: bash

   ./cosign.py --directory=path/to/tar/files --dry-run

Step 5: Verify the Signatures

After signing, you can verify the signatures using cosign:

.. code-block:: bash

   cosign verify <image_name> --key cosign.pub

Test
----

Install container-structure-test:

.. code-block:: bash

   curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
   chmod +x container-structure-test-linux-amd64
   sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

Test a Single Image with a Specific Config:

.. code-block:: bash

   ./scripts/container_test.py --image 12ef04ba60b2 --config test/debian11-nodejs-23.11.0.yaml


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
