# Verifying Container Image Signatures

This example demonstrates how to verify the signatures of container images using GPG and Cosign.

## Prerequisites

- Container Tools installed
- GPG installed (for GPG verification)
- Cosign installed (for Cosign verification)
- Public key of the signer

## GPG Verification Example

### 1. Verify a signed tarball

To verify a tarball that has been signed with GPG:

```bash
./scripts/gpg.py --directory dist/debian11-java-slim --verify
```

This will look for a `.asc` signature file alongside the tarball and verify it.

### 2. Verify with a specific signature file

If the signature file is in a different location or has a different name:

```bash
./scripts/gpg.py --directory dist/debian11-java-slim --verify --sig-file /path/to/signature.asc
```

### 3. Import the signer's public key (if needed)

If you don't have the signer's public key in your keyring:

```bash
gpg --import signer_public_key.asc
```

## Cosign Verification Example

### 1. Verify a container image in a registry

```bash
cosign verify myregistry.com/myrepo/debian11-java-slim:latest --key cosign.pub
```

### 2. Verify with keyless signing (Sigstore)

If the image was signed using keyless signing:

```bash
COSIGN_EXPERIMENTAL=1 cosign verify myregistry.com/myrepo/debian11-java-slim:latest
```

### 3. Verify with a certificate identity

```bash
cosign verify myregistry.com/myrepo/debian11-java-slim:latest --key cosign.pub --certificate-identity=user@example.com
```

## Verification in CI/CD Pipelines

Example GitHub Actions workflow for verification:

```yaml
name: Verify Container Image

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      
      - name: Install Cosign
        uses: sigstore/cosign-installer@v1
      
      - name: Verify image signature
        run: |
          cosign verify \
            myregistry.com/myrepo/debian11-java-slim:latest \
            --key cosign.pub
```

## Troubleshooting

- If verification fails with "no valid signatures found", ensure you're using the correct public key
- For GPG verification issues, check that the signature file matches the tarball
- For Cosign registry issues, ensure you have proper authentication to the registry
