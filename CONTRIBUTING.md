# Contributing to Container Tools

Thanks for taking the time to contribute!

This project builds minimal Debian rootfs artifacts, adds optional security scanning, and includes testing/signing helpers. Please follow the guidelines below to keep contributions consistent, secure, and maintainable.

## Getting Started

- Required tools: make, git, Docker, debootstrap, curl, unzip
- Optional tools: trivy, cosign, container-structure-test
- Recommended OS: Linux or a Linux VM (Vagrant and Dockerfile are provided)

Clone and list available targets:
- make help

Run a full test pass:
- make test

Lint shell scripts:
- make shellcheck

## Development Workflow

1) Create an issue describing the change.
2) Use topic branches:
   - feature/<short-name>
   - fix/<short-name>
   - chore/<short-name>
3) Prefer Conventional Commits for clarity:
   - feat: add support for <x>
   - fix: correct <y>
   - docs: update README
   - refactor:, chore:, test:, ci:, build:
4) Add or update tests where applicable (see test/ directory and scripts/test.py).
5) Ensure security scan is optional and non-failing when Trivy isn’t installed (already handled in scripts/security-scan.sh and debian/mkimage.sh).

## Commit and Tag Signing

All commits and release tags should be cryptographically signed:
- Signed commits: git commit -S -m "feat: ... "
- Signed tags: git tag -s vX.Y.Z -m "vX.Y.Z"

See GitHub documentation for setting up SSH or GPG signing:
- https://docs.github.com/authentication/managing-commit-signature-verification

## Versioning and Releases

We follow Semantic Versioning (SemVer):
- MAJOR: incompatible changes
- MINOR: backward-compatible features
- PATCH: backward-compatible bug fixes

Release process:
1) Update CHANGELOG.md (Unreleased -> X.Y.Z).
2) Create a signed tag vX.Y.Z.
3) Push commits and tags.
4) Optionally publish a GitHub Release.

Note: The Makefile uses git describe when available, so tagging drives the visible version.

## Testing

- Build artifacts with make <target>.
- Test images with:
  - make test (auto-imports tar if image not present)
  - or scripts/test.py --image <name> --config test/<name>.yaml
- Security scans (optional):
  - scripts/security-scan.sh --target <path> [--dist ./dist]

## Code Style

- Bash: set -euo pipefail in scripts, avoid parsing human output, prefer machine-readable formats.
- Python: keep scripts idempotent, avoid leaking secrets, prefer return codes over exceptions for CLI checks.
- Docker: avoid apt-key; clean apt cache in the same layer; pin signing keys via signed-by.

## Conduct

Be respectful and constructive. We’re happy to help with first-time contributions.
