# Container Tools Examples

This directory contains practical examples demonstrating how to use Container Tools for various use cases.

## Categories

- **Debian**: Basic Debian image creation and customization
- **Java**: Java application containerization with different JVM variants
- **NodeJS**: NodeJS application deployment
- **Security**: Image signing and verification
- **Testing**: Container structure testing

## Getting Started

Each example includes:
- Step-by-step instructions
- Sample commands
- Expected outputs
- Troubleshooting tips

Choose an example that matches your use case to get started quickly.

## Multi-architecture builds with Docker Buildx

You can build and publish multi-arch images (e.g., linux/amd64 and linux/arm64) using Docker Buildx. The provided Dockerfile already supports multi-arch by using TARGETOS/TARGETARCH/TARGETVARIANT to download the correct binaries per architecture.

### Prerequisites
- Docker Desktop (or Docker Engine) with Buildx enabled.
- A registry you can push to (multi-arch manifests require a registry).

### Build and push a multi-arch image
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/your-image:latest . --push
```

Notes:
- Use --push to publish a multi-arch manifest list to your registry.
- Use --load only for a single platform build (e.g., --platform linux/arm64) as Docker cannot load a multi-arch manifest into the local daemon.

### Verifying the built image
```bash
docker buildx imagetools inspect your-registry/your-image:latest
```

You should see entries for both linux/amd64 and linux/arm64.

### Alternative: wrap a rootfs tarball (FROM scratch)
If your pipeline produces a root filesystem tarball (e.g., via debootstrap), you can keep that flow and still build multi-arch images. Use a minimal Dockerfile that wraps each arch-specific tarball:

Example Dockerfile:
```Dockerfile
# syntax=docker/dockerfile:1.6
FROM scratch
ARG TARGETARCH
ADD rootfs-${TARGETARCH}.tar /
# Set default config as needed, e.g.:
CMD ["/bin/sh"]
```

Build and push multi-arch:
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/your-image:latest . --push
```

Tips:
- Name your tarballs with the arch suffix (e.g., rootfs-amd64.tar, rootfs-arm64.tar).
- BuildKit supports using ARG values (like TARGETARCH) in ADD with the modern Dockerfile syntax line.
- Prefer deterministic, reproducible tarball contents and verify with signing tools as shown in the Security examples.
