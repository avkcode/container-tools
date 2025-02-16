Scripts for building Docker base images:
```
Usage: make <\target>

 * 'print-%' - print-{VAR} - Print variables


 * 'shellcheck' - Bash scripts linter

 * 'install-qemu-user-static' - Register binfmt_misc, qemu-user-static

 ============================
  ** Debian Linux targets **
 ============================

|debian11|
|debian11-java|
|debian11-java-slim|
|debian11-corretto|
|debian11-graal|
|debian11-graal-slim|
|debian11-java-slim-maven|
|debian11-java-slim-gradle|
```

Debian RootFS Builder
This project provides a script and a Makefile to automate the creation of minimal Debian-based root filesystems (rootfs) using debootstrap. The rootfs can be customized with specific packages, configurations, and security scans, making it suitable for containers, virtual machines, or custom environments.

Features

Debootstrap-based rootfs creation: Builds minimal Debian rootfs with specified packages and configurations.
Customizable: Supports custom packages, scripts, and configurations.
Security scanning: Integrates with trivy to scan the rootfs for vulnerabilities.
Artifact generation: Outputs a compressed .tar file of the rootfs and an MD5 checksum for verification.
Docker-ready: Provides instructions to load and run the rootfs as a Docker image.
Makefile support: Simplifies the build process with predefined targets for different rootfs configurations.
Prerequisites

Debian/Ubuntu-based system: The script and Makefile are designed to run on GNU/Linux systems.
Root privileges: The script requires root access to create the rootfs.
Dependencies:
debootstrap: For creating the rootfs.
unzip: For handling compressed files.
trivy: For security scanning (optional but recommended).
podman or docker: For container runtime (optional).
make: For using the Makefile.
Project Structure

```
.
├── debian/                  # Debian-specific files
│   ├── keys/                # GPG keys for package verification
│   └── mkimage.sh           # Main script for building rootfs
├── recipes/                 # Custom scripts for rootfs configuration
│   └── java/                # Java-specific recipes
├── scripts/                 # Post-build scripts (e.g., security scans)
├── tools.mk                 # Makefile tools and utilities
├── Makefile                 # Makefile for building rootfs
└── README.md                # This file
```

Usage:

The script is located in the debian/ directory and can be run directly. It accepts several arguments to customize the rootfs build process.

Script Arguments

```
Argument	Description
--name=<name>	Name of the rootfs image.
--release=<release>	Debian release (e.g., buster, bullseye).
--keyring=<keyring>	Path to the GPG keyring for package verification.
--variant=<variant>	Debootstrap variant (e.g., minbase, buildd).
--repo_config=<file>	Path to the repository configuration file.
--debootstrap_packages=<packages>	Comma-separated list of packages to include during debootstrap.
--packages=<packages>	Comma-separated list of additional packages to install in the rootfs.
--recipes=<scripts>	Comma-separated list of scripts to run during the build process.
--scripts=<scripts>	Comma-separated list of scripts to run after the build process.
--help	Display usage information.
```
