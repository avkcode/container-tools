# Customizing Debian Images with Additional Packages

This example shows how to create a Debian-based image with custom package selection.

## Prerequisites

- Container Tools installed
- Basic understanding of Debian package management

## Adding Custom Packages

### 1. Create a custom package list

Create a new configuration file or modify an existing one in `debian/debootstrap/`:

```bash
cp debian/debootstrap/bullseye debian/debootstrap/bullseye-custom
```

Edit the file to include your desired packages:

```bash
# Basic system packages
DEBOOTSTRAP_COMPONENTS="main"
DEBOOTSTRAP_VARIANT="minbase"
DEBOOTSTRAP_INCLUDE="ca-certificates,curl,locales,procps,apt-transport-https"

# Add your custom packages here
DEBOOTSTRAP_INCLUDE="${DEBOOTSTRAP_INCLUDE},vim,git,htop,net-tools"
```

### 2. Create a new Makefile target

Add a new target to the Makefile:

```makefile
debian11-custom: debian/debootstrap/bullseye-custom
	@echo "Building custom Debian 11 image..."
	@mkdir -p $(DIST)/debian11-custom
	@TARGET=debian11-custom DIST=$(DIST)/debian11-custom DEBOOTSTRAP_CONF=$< ./debian/mkimage.sh
```

### 3. Build the custom image

```bash
make debian11-custom
```

### 4. Load and test the image

```bash
cat dist/debian11-custom/debian11-custom.tar | docker import - debian11-custom:latest
docker run -it debian11-custom:latest /bin/bash
```

Verify your custom packages are installed:

```bash
which vim git htop
```

## Creating a Minimal Development Environment

Here's an example of creating a minimal development environment:

```bash
# In debian/debootstrap/bullseye-dev
DEBOOTSTRAP_COMPONENTS="main"
DEBOOTSTRAP_VARIANT="minbase"
DEBOOTSTRAP_INCLUDE="ca-certificates,curl,locales,procps,apt-transport-https"
DEBOOTSTRAP_INCLUDE="${DEBOOTSTRAP_INCLUDE},build-essential,git,vim,ssh,python3,python3-pip"
```

Then build with:

```bash
make debian11-dev
```

## Troubleshooting

- If packages fail to install, check they're available in the Debian repository
- For dependency issues, you may need to add additional packages to resolve them
- To debug package installation, check the build logs in the output directory
