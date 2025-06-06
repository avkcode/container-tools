# Creating a Basic Alpine Linux Image

This example demonstrates how to create a minimal Alpine Linux container image using Container Tools.

## Prerequisites

- Linux system with root access
- Alpine Linux tools installed
- Container Tools repository cloned

## Steps

### 1. Build a Basic Alpine Linux Image

```bash
# Create a basic Alpine Linux 3.19 image
sudo make alpine3.19
```

This command creates a minimal Alpine Linux 3.19 rootfs in the `dist/alpine3.19` directory.

### 2. Import the Image into Docker

```bash
# Import the rootfs into Docker
cat dist/alpine3.19/alpine3.19.tar | docker import - alpine3.19-base
```

### 3. Run the Container

```bash
# Run a shell in the container
docker run -it alpine3.19-base /bin/sh
```

### 4. Verify the Alpine Version

Inside the container, run:

```bash
cat /etc/alpine-release
```

You should see the Alpine version (e.g., 3.19.1).

## Customizing the Alpine Image

### Adding Custom Packages

You can specify additional packages to include in the base image:

```bash
sudo ./alpine/mkimage.sh --alpine-version=v3.19 --packages="alpine-base curl jq" --output-dir=./dist
```

### Using a Different Mirror

To use a specific Alpine mirror:

```bash
sudo ./alpine/mkimage.sh --alpine-version=v3.19 --mirror="https://alpine.mirror.example.com/alpine" --output-dir=./dist
```

## Troubleshooting

### Common Issues

1. **Permission denied**: Ensure you're running the commands with sudo.
2. **Missing Alpine tools**: Install Alpine Linux tools on your host system.
3. **Network issues**: Check your internet connection and firewall settings.

## Next Steps

- Try building specialized Alpine images with Node.js or Java
- Explore container structure testing for your Alpine images
- Create multi-stage builds using your Alpine base images
