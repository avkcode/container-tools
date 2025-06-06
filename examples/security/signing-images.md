# Signing Container Images

This example demonstrates how to sign container images using GPG and Cosign.

## Prerequisites

- Container Tools installed
- GPG key pair for signing
- Cosign installed (for Cosign examples)

## GPG Signing Example

### 1. Build a container image

```bash
make debian11-java-slim
```

### 2. Sign the image with GPG

```bash
./scripts/gpg.py --directory dist/debian11-java-slim --gpg-key-id YOUR_KEY_ID
```

### 3. Verify the signature

```bash
./scripts/gpg.py --directory dist/debian11-java-slim --verify
```

## Cosign Signing Example

### 1. Generate a Cosign key pair (if you don't have one)

```bash
cosign generate-key-pair
```

### 2. Sign the image with Cosign

```bash
./scripts/cosign.py --directory dist/debian11-java-slim --key cosign.key
```

### 3. Push to a registry with signature

```bash
./scripts/cosign.py --directory dist/debian11-java-slim --key cosign.key --registry myregistry.com/myrepo
```

### 4. Verify the signature

```bash
cosign verify myregistry.com/myrepo/debian11-java-slim:latest --key cosign.pub
```

## Troubleshooting

- If GPG signing fails, ensure your GPG key is properly set up with `gpg --list-keys`
- For Cosign errors, check that the image was properly loaded with `docker images`
