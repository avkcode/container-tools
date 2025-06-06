# Creating a Basic Debian Image

This example demonstrates how to create a minimal Debian-based container image.

## Prerequisites

- Container Tools installed
- Docker installed
- debootstrap installed
- sudo privileges

## Steps

### 1. Build a basic Debian 11 image

```bash
make debian11
```

This command creates a minimal Debian 11 (Bullseye) rootfs using debootstrap.

### 2. Check the build output

The built image will be available in the `dist/` directory:

```bash
ls -la dist/debian11/
```

You should see a `.tar` file containing your Debian rootfs.

### 3. Load the image into Docker

```bash
cat dist/debian11/debian11.tar | docker import - debian11:latest
```

### 4. Test the image

```bash
docker run -it debian11:latest /bin/bash
```

Inside the container, you can verify it's a minimal Debian system:

```bash
cat /etc/os-release
```

## Customization Options

To customize the basic Debian image, you can:

1. Modify the `debian/debootstrap/debian11.conf` file to include additional packages
2. Create a custom recipe in the `recipes/` directory
3. Add a new target to the Makefile

## Troubleshooting

- If the build fails with permission errors, ensure you're running with sudo privileges
- For network-related issues, check your internet connection and proxy settings
- If debootstrap fails, ensure you have the correct Debian release name in your configuration
