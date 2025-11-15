Container Tools
=============

.. image:: https://raw.githubusercontent.com/avkcode/container-tools/refs/heads/main/favicon.svg
   :alt: Container Tools Logo
   :width: 80px
   :align: right

Container Tools provides scripts and utilities to automate the creation of minimal root filesystems (rootfs) using debootstrap for Debian-based Linux. It supports customization with specific packages, configurations, and integrates security scanning for containerized environments. Easily extensible for other distros and projects.

Rationale
--------

Traditional Dockerfile-based builds suffer from several inefficiencies:

- **Storage bloat**: Each ``RUN apt-get install`` creates a new layer, wasting disk space with duplicate dependencies
- **Network inefficiency**: Redundant package downloads across different images
- **Slow iterations**: Rebuilding images requires repeating all previous steps

This tool enables you to:

- Build minimal base images from scratch using debootstrap
- Precisely include only required components in the initial build
- Create specialized variants (Java, etc.) from common foundations

Features
--------

- Lightweight rootfs generation for Debian Linux
- Customizable package selection
- Security scanning integration (Trivy)
- Support for Java variants (Standard, GraalVM, Corretto)
- Build tool integration (Maven, Gradle)
- Clean host build via Firecracker sandbox

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
   debian11-nodejs-23.11.0
   debian11-cuda-runtime

Using Built Images
~~~~~~~~~~~~~~~~~

After successful build:

.. code-block:: bash

   # Load the image
   cat debian/dist/debian11-graal-slim/debian11-graal-slim.tar | docker import - debian11-graal-slim

   # Run the container
   docker run -it debian11-graal-slim /bin/bash

CUDA Runtime Base (GPU)
~~~~~~~~~~~~~~~~~~~~~~~

This repository includes a CUDA-ready base image that integrates with the NVIDIA Container Toolkit.

- Target: debian11-cuda-runtime
- Requires: NVIDIA drivers on the host and the NVIDIA Container Toolkit
- Run with GPU access:

.. code-block:: bash

   make debian11-cuda-runtime
   docker run --rm -it --gpus all debian11-cuda-runtime nvidia-smi

Note: The image is minimal and relies on the host toolkit to inject GPU drivers and binaries at runtime. For most workflows, you do not need to bundle CUDA libraries into the image.

Environment Variables
---------------------

Container Tools can be driven via environment variables. The Makefile exports all variables to child processes, so environment variables override defaults and are visible to scripts.

Core build controls:

- VARIANT: Select the debootstrap variant: container, fakechroot, minbase (default: container)
- RELEASE: Debian codename to build (default: bullseye)
- DOCKER_CMD: Container CLI to use, e.g., docker or podman (default: docker)
- DIST_DIR: Output directory for built images and artifacts (default: debian/dist)
- DOWNLOADS_DIR: Directory for downloaded artifacts (default: download)

Component versions (override as needed):

- JAVA_VERSION (default: 21.0.1)
- GRAALVM_VERSION (default: 20.0.2)
- CORRETTO_VERSION (default: 17.0.9.8.1)
- MAVEN_VERSION (default: 3.8.8)
- GRADLE_VERSION (default: 7.4.2)
- NODE_VERSION (default: 23.11.0)
- PYTHON_VERSION (default: 3.9.18)
- KAFKA_VERSION (default: 4.0.0)

Build metadata (auto-set, but overridable):

- VERSION, BUILD_DATE, GIT_REVISION

Security scanning:

- CT_SKIP_SECURITY_SCAN: Set to 1/true/yes to skip Trivy scanning during builds
- target, dist: Environment fallbacks used by scripts/security-scan.sh for scan target path and output directory

Docker Buildx context:

- TARGETOS, TARGETARCH, TARGETVARIANT: Provided by Buildx during docker buildx builds; exported in the Dockerfile for use by tooling. Normally you do not need to set these manually.

Examples:

.. code-block:: bash

   export VARIANT=minbase RELEASE=bullseye
   export NODE_VERSION=23.11.0 DIST_DIR=out
   export CT_SKIP_SECURITY_SCAN=1
   make debian11-nodejs-23.11.0

   # Use env fallbacks with the security scan script
   export target="./debian/dist/debian11-nodejs-23.11.0/rootfs" dist="./debian/dist/debian11-nodejs-23.11.0"
   ./scripts/security-scan.sh

Multi-architecture Images with Docker Buildx
--------------------------------------------

You can build and publish multi-arch images (for example, linux/amd64 and linux/arm64) using Docker Buildx. The provided Dockerfile and recipes work well with BuildKit’s TARGETOS/TARGETARCH args, or you can wrap arch-specific rootfs tarballs into tiny scratch-based images.

Prerequisites:

- Docker Desktop (or Docker Engine) with Buildx enabled
- A container registry you can push to

Build and push a multi-arch image:

.. code-block:: bash

   docker buildx create --use
   docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/your-image:latest . --push

Notes:

- Use ``--push`` to publish a multi-arch manifest list to your registry.
- Use ``--load`` only for a single-platform build, since Docker cannot load a multi-arch manifest into the local daemon.

Verify the built image:

.. code-block:: bash

   docker buildx imagetools inspect your-registry/your-image:latest

Alternative: wrap a rootfs tarball (FROM scratch)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If your pipeline produces a root filesystem tarball (for example, via debootstrap), you can keep that flow and still build multi-arch images. Use a minimal Dockerfile that wraps each arch-specific tarball:

.. code-block:: dockerfile

   # syntax=docker/dockerfile:1.6
   FROM scratch
   ARG TARGETARCH
   ADD rootfs-${TARGETARCH}.tar /
   # Set defaults as needed, for example:
   CMD ["/bin/sh"]

Build and push multi-arch with the wrapper:

.. code-block:: bash

   docker buildx create --use
   docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/your-image:latest . --push

Tips:

- Name your tarballs with the arch suffix (for example, ``rootfs-amd64.tar``, ``rootfs-arm64.tar``).
- BuildKit supports using ARG values (like ``TARGETARCH``) in ``ADD`` with the modern Dockerfile syntax line.
- Prefer deterministic, reproducible tarball contents and verify with the signing tools shown in the Security section.

Extending the Tool
-----------------

To add new components:

1. Create a recipe in ``recipes/`` directory
2. Verify artifact URLs and SHA256 checksums
3. Add a new target to the Makefile

Clean Host Building with Firecracker
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
If you want to compile custom Kernel use ``tools/download-and-build-kernel.sh`` script.

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
   │   ├── java/            # Java variants for Debian
   ├── scripts/             # Maintenance scripts
   ├── debian/dist/         # Output images
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

   ./scripts/cosign.py --directory=path/to/tar/files

Use a Private Key for Signing
Sign images using the private key generated earlier:

.. code-block:: bash

   ./scripts/cosign.py --directory=path/to/tar/files --key=cosign.key

Push Signed Images to a Registry
Push signed images to a container registry:

.. code-block:: bash

   ./scripts/cosign.py --directory=path/to/tar/files --registry=myregistry.com/myrepo

Perform a Dry Run
Simulate the signing process without executing commands:

.. code-block:: bash

   ./scripts/cosign.py --directory=path/to/tar/files --dry-run

Registry vs Local Signing

Cosign typically signs images that have been pushed to a container registry and references them by digest. If you prefer not to push, you can sign local artifacts using OCI references:
- ocidir:/path/to/oci-directory
- oci-archive:/path/to/image.tar

The helper script at ./scripts/cosign.py will import filesystem tarballs and tag them locally; when --registry is provided it will push before signing. Without a registry, it will sign using the local image ID.

Step 5: Verify the Signatures

After signing, you can verify the signatures using cosign:

.. code-block:: bash

   cosign verify <image_name> --key cosign.pub

Test
----

Container-structure-test is a CLI tool for validating container images.
It ensures images meet configuration, security, and compliance standards by running tests against file structures,
metadata, environment variables, and commands within the image.
Ideal for CI/CD pipelines, it helps catch issues early and ensures consistent, reliable container builds.

Install container-structure-test:

.. code-block:: bash

   curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
   chmod +x container-structure-test-linux-amd64
   sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

Image naming and test configs:

Each build target creates a tarball at debian/dist/<name>/<name>.tar and, when imported, a local Docker image tagged as <name>. The Makefile's test target will automatically import the tarball if the image tag does not exist. Test configurations are located at test/<name>.yaml and should reference the same image tag.

.. code-block:: bash

   ./scripts/test.py --image debian11-nodejs-23.11.0 --config test/debian11-nodejs-23.11.0.yaml

Examples
--------

For practical examples of how to use Container Tools, see the `examples/` directory:

- Debian image customization
- Java application containerization
- Security signing and verification
- Container structure testing
- End-to-end build → scan → test → sign → verify flow

Each example includes step-by-step instructions and sample commands.


Security
--------

All builds include automated security scanning via Trivy in the ``security-scan.sh`` script.

Disabling the security scan
~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Temporarily skip scans by setting an environment variable before running a build:

  .. code-block:: bash

     export CT_SKIP_SECURITY_SCAN=1
     make debian11-graal-slim

- To omit including the scan script entirely at build time (Makefile will not pass --scripts), set:

  .. code-block:: bash

     export CT_DISABLE_SECURITY_SCAN=1
     make debian11-graal-slim

- Or pass the skip flag if you call the script directly:

  .. code-block:: bash

     ./scripts/security-scan.sh --skip --target ./debian/dist/debian11-graal-slim/rootfs --dist ./debian/dist/debian11-graal-slim

- If Trivy is not installed, the script automatically skips scanning and exits successfully with a warning.

Contributing
------------

Contributions are welcome. Please submit issues or pull requests for:

- New distro support
- Additional package recipes
- Security improvements
- Documentation enhancements
