<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Container Tools</title>
</head>
<body>
    <table>
        <tr>
            <td valign="top" width="100">
                <img src="https://raw.githubusercontent.com/avkcode/container-tools/refs/heads/main/favicon.svg"
                     alt="Container Tools"
                     width="80">
            </td>
            <td valign="middle">
                Container Tools is a project that provides scripts and utilities to automate the creation of minimal Debian-based root filesystems (rootfs) using debootstrap. It supports customization with specific packages, configurations, and integrates security scanning for containerized environments.
            </td>
        </tr>
    </table>
</body>
</html>

<svg width="100%" height="40" viewBox="0 0 240 40" xmlns="http://www.w3.org/2000/svg" style="margin: 20px 0;">
  <defs>
    <linearGradient id="gold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fff8d8"/>
      <stop offset="30%" stop-color="#f7e394"/>
      <stop offset="50%" stop-color="#e6c35a"/>
      <stop offset="70%" stop-color="#c59b3a"/>
      <stop offset="100%" stop-color="#a67c00"/>
    </linearGradient>

    <!-- Velvet Background -->
    <radialGradient id="velvet" cx="50%" cy="50%" r="80%">
      <stop offset="0%" stop-color="#3b1f47"/>
      <stop offset="50%" stop-color="#2a1233"/>
      <stop offset="100%" stop-color="#1a0c1f"/>
    </radialGradient>

    <!-- Dotted Pattern -->
    <pattern id="dottedPattern" patternUnits="userSpaceOnUse" width="10" height="10">
      <circle cx="2" cy="2" r="1" fill="#5a3d6b" opacity="0.6"/>
    </pattern>
  </defs>

  <rect width="100%" height="40" fill="url(#velvet)"/>

  <rect width="100%" height="40" fill="url(#dottedPattern)"/>

  <line x1="10" y1="20" x2="calc(100% - 10)" y2="20" stroke="url(#gold)" stroke-width="4" stroke-linecap="round"/>
</svg>


Scripts for building Docker base images:
```
make

Usage: make <target>

 * 'print-%' - print-{VAR} - Print variables


 * 'shellcheck' - Bash scripts linter

 * 'qemu-user-static' - Register binfmt_misc, qemu-user-static

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
|debian11-graal-slim-maven|
|debian11-graal-slim-gradle|
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

```
[Image was built successfully]
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Artifact location: debian/dist/debian11-java-slim-maven/debian11-java-slim-maven.tar

Artifact size: 113M

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Image was built successfully!
Artifact location: debian/dist/debian11-java-slim-maven/debian11-java-slim-maven.tar

To load and run this Docker image, follow these steps:

1. Load the Docker image from the .tar file:
   cat debian/dist/debian11-java-slim-maven/debian11-java-slim-maven.tar | docker import - debian/dist/debian11-java-slim-maven/debian11-java-slim-maven

2. Verify the image was loaded successfully:
   docker images

3. Run the Docker container:
   docker run -it <IMAGE_NAME>
   Replace <IMAGE_NAME> with the name of the image loaded in step 1.

Example:
   docker run -it debian/dist/debian11-java-slim-maven/debian11-java-slim-maven
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Time elapsed: 83
```

# Extending

To extend this script and Makefile to create new images, you can follow these steps:

1. Understand the Structure

Makefile: The Makefile contains targets for building different Debian-based images. Each target corresponds to a specific image variant (e.g., debian11, debian11-java, etc.).
Recipes: The recipes directory contains shell scripts that define the setup for different components (e.g., Java, GraalVM, Maven, Gradle). These scripts are executed during the image build process.
Scripts: The scripts directory contains additional scripts that are run during the build process, such as security scans.
2. Add a New Recipe

If you want to add a new image variant, you need to create a new recipe script in the recipes directory. For example, if you want to create an image with Node.js, you would create a new script nodejs.sh in the recipes directory.

Example: recipes/nodejs.sh
```
#!/bin/bash
set -e
```
# Install Node.js
```
apt-get update
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs
```
# Clean up
```
apt-get clean
rm -rf /var/lib/apt/lists/*
```

3. Add a New Target in the Makefile

Once you have created the recipe, you need to add a new target in the Makefile to build the image using that recipe.

Example: Add debian11-nodejs Target

```
debian11-nodejs:
    $(PRINT_HEADER)
    $(DEBIAN_BUILD_SCRIPT) \
        --name=$@ \
        --keyrign=$(DEBIAN_KEYRING) \
        --variant=container \
        --release=stable \
        --recipes=$(RECIPES)/nodejs.sh \
        --scripts=$(SCRIPTS)/security-scan.sh
```

4. Update the help Target

Update the help target in the Makefile to include the new image variant in the usage instructions.

Example: Update help Target

```
help:
    @echo
    @echo "Usage: make <target>"
    @echo
    @echo " * 'print-%' - print-{VAR} - Print variables"
    @echo
    @echo
    @echo " * 'shellcheck' - Bash scripts linter"
    @echo
    @echo " * 'qemu-user-static' - Register binfmt_misc, qemu-user-static"
    @echo
    @echo " ============================"
    @echo "  ** Debian Linux targets ** "
    @echo " ============================"
    @echo
    @echo "|debian11|"
    @echo "|debian11-java|"
    @echo "|debian11-java-slim|"
    @echo "|debian11-corretto|"
    @echo "|debian11-graal|"
    @echo "|debian11-graal-slim|"
    @echo "|debian11-java-slim-maven|"
    @echo "|debian11-java-slim-gradle|"
    @echo "|debian11-graal-slim-maven|"
    @echo "|debian11-graal-slim-gradle|"
    @echo "|debian11-nodejs|"
```

5. Build the New Image

You can now build the new image using the make command with the new target.

Example: Build debian11-nodejs Image

```
make debian11-nodejs
```

6. Test the New Image

After building the image, you should test it to ensure that it works as expected. You can run the image using Docker and verify that Node.js is installed correctly.

Example: Test debian11-nodejs Image

```
docker run -it debian11-nodejs node --version
```

7. Optional: Combine Recipes

If you want to create an image that combines multiple components (e.g., Node.js and Java), you can specify multiple recipes in the --recipes argument.

Example: Combine Node.js and Java Recipes

```
debian11-nodejs-java:
    $(PRINT_HEADER)
    $(DEBIAN_BUILD_SCRIPT) \
        --name=$@ \
        --keyrign=$(DEBIAN_KEYRING) \
        --variant=container \
        --release=stable \
        --recipes=$(RECIPES)/nodejs.sh,$(JAVA_RECIPES)/java.sh \
        --scripts=$(SCRIPTS)/security-scan.sh
```

8. Optional: Add Additional Scripts

If you need to run additional scripts during the build process (e.g., custom configuration or setup), you can add them to the scripts directory and reference them in the --scripts argument.

Summary

Create a new recipe in the recipes directory for the new component.
Add a new target in the Makefile to build the image using the new recipe.
Update the help target to include the new image variant.
Build and test the new image.
By following these steps, you can easily extend the script and Makefile to create new images with different components and configurations.
