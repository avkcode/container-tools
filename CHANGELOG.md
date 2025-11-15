# Changelog

All notable changes to this project will be documented in this file.

The format is based on “Keep a Changelog” and this project adheres to Semantic Versioning (SemVer).

- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- Semantic Versioning: https://semver.org/

## [Unreleased]

- Document contribution and security processes (this file, CONTRIBUTING.md, SECURITY.md, CODEOWNERS)
- CI-friendly security scanning output via scripts/security-scan.sh
- Clarify image naming, test configs, and cosign usage in README

## [0.1.0] - 2025-11-15

### Added
- Optional installation of cosign and container-structure-test in the development Dockerfile
- Vagrantfile support for VirtualBox and Libvirt providers; headless by default; provisioning of Docker/Podman and tooling
- Auto-import of images in Makefile test target if Docker image tag is missing
- scripts/cosign.py: proper reference signing (repo:tag or repo@digest), verification mode, OCI local signing
- scripts/gpg.py: secure passphrase handling, force overwrite flag, proper tar validation via exit code
- scripts/test.py: correct Docker image validation via return code; run container-structure-test once
- scripts/security-scan.sh: robust flags, set -euo pipefail, JSON output for CI, exit codes driven by Trivy
- debian/mkimage.sh: optional Trivy scan, chroot-safe recipe execution, cleanup trap, sha256 checksums

### Changed
- Dockerfile: avoid apt-key, use signed-by keyrings; clean apt cache within the same layer
- README: fix script paths and clarify registry vs local signing; document image tag/test mapping
- Makefile: expanded PHONY targets and DOCKER_CMD var

### Security
- Prefer sha256 over md5 for artifact integrity
- Enforce non-interactive behaviors and cleanup for safer builds

[0.1.0]: https://github.com/avkcode/container-tools/releases/tag/v0.1.0
