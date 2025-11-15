# Container Tools – Improvement Plan

This document consolidates targeted, actionable improvements across code quality, security, reproducibility, and developer experience.

Sections
- High-impact fixes (by file)
- Reproducibility and security
- CI/CD and pre-commit
- Developer UX (Makefile, README, Dockerfile, Vagrant)
- Optional quality improvements
- Files requested for deeper review

---

## High-impact fixes (by file)

### 1) scripts/utils.py
- Problem:
  - run_command uses shell=True (risk of injection), doesn’t return exit code; callers mis-handle failures.
- Changes:
  - Use subprocess.run([...], shell=False).
  - Return (stdout, stderr, returncode).
  - Consider adding a timeout and masking secrets in logs.

### 2) scripts/test.py
- Problems:
  - validate_image uses exceptions; with current utils it always “succeeds”.
  - container-structure-test runs twice (once via run_command and once via subprocess.run).
- Changes:
  - Use rc from run_command(["docker","inspect","--type=image", image_id]); return rc == 0.
  - Build command once; run only once; treat rc != 0 as failure; log outputs.

### 3) scripts/gpg.py
- Problems:
  - Passphrase via CLI leaks secrets; overwrite prompt blocks CI; tar validation checks stderr rather than exit code.
- Changes:
  - Add --force to skip overwrite prompts in CI.
  - If passphrase required and not provided, use getpass.getpass(); use --pinentry-mode loopback; never echo secrets.
  - Validate tar via tar -tf and check return code.

### 4) scripts/cosign.py
- Problems:
  - Signs digest/image ID incorrectly; cosign expects repo:tag or repo@digest; no verify flow.
- Changes:
  - Sign the proper reference (tag or repo@digest). After import/tag, sign final_tag; after push, sign repo@digest if desired.
  - Require --registry for push/sign flows or add ocidir:/oci-archive: support for local signing.
  - Add verify mode: cosign verify <repo:tag|repo@digest> [--key KEY].

### 5) scripts/security-scan.sh
- Problems:
  - Relies on env vars; greps human output; lacks set -u and pipefail.
- Changes:
  - set -euo pipefail.
  - Parse flags: --target, --dist (default dist=./dist).
  - Use Trivy exit codes directly:
    - trivy fs --severity CRITICAL --exit-code 1 --no-progress "$target"
  - Produce machine-readable output for CI:
    - --format json --output "$dist/security_scan.json"

### 6) debian/mkimage.sh
- Problems:
  - Trivy is a hard requirement; no cleanup trap; uses md5; recipes may apt-get on host.
- Changes:
  - Gate Trivy usage: if not found, warn and skip scan.
  - Add trap to always umount chroot mounts and cleanup temp dirs on exit/failure.
  - Use sha256sum for archive checksums.
  - Ensure recipes run in chroot or operate only on $target paths; iterate scripts like recipes and run each entry.

### 7) alpine/mkimage.sh
- Problems:
  - Lacks nounset; apk cache may remain; uses md5 for checksums.
- Changes:
  - set -o nounset and add trap to cleanup "$target" and "$tmpdir".
  - Use apk --root "$rootfs_dir" add --no-cache $packages; remove /var/cache/apk/*.
  - Use sha256sum for the final tar checksum.

### 8) recipes/nodejs/nodejs.sh
- Problems:
  - URL uses “latest” → non-reproducible; apt-get runs on host; cleanup affects host; env appended to /etc/profile.
- Changes:
  - Use pinned URL:
    - https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz
  - Avoid host apt; if needed, install inside target via chroot "$target" apt-get … and clean inside $target.
  - Verify via chroot "$target" /opt/nodejs/bin/node --version.
  - Write env to "$target/etc/profile.d/nodejs.sh" and chmod 644.
  - Note: 23.x is “Current,” not LTS—fix comment.

### 9) recipes/python/python.sh
- Problems:
  - Build deps installed on host; build runs outside target; host cleanup.
- Changes:
  - Install build deps inside target chroot.
  - Extract under "$target/usr/src/python" and build using chroot "$target" bash -c 'cd /usr/src/python && ./configure … && make && make install'.
  - Cleanup inside target (purge build deps, autoremove, rm -rf "$target/var/lib/apt/lists/*").
  - Verify via chroot "$target" /usr/bin/python3 --version.

### 10) recipes/kafka/kafka.sh
- Problems:
  - Uses undefined error function; Kafka 4.0 uses KRaft (no ZooKeeper) but script config/startup uses ZooKeeper; env only in root’s bashrc; runs as root.
- Changes:
  - Replace error … with die "Kafka requires Java to be installed …".
  - Switch to KRaft config:
    - listeners=PLAINTEXT://:9092,CONTROLLER://:9093
    - advertised.listeners=PLAINTEXT://localhost:9092
    - process.roles=broker,controller
    - node.id=1
    - controller.listener.names=CONTROLLER
    - inter.broker.listener.name=PLAINTEXT
    - controller.quorum.voters=1@localhost:9093
    - log.dirs=/var/lib/kafka/data
  - Initialize storage once before first start:
    - /opt/kafka/bin/kafka-storage.sh format -t "${KAFKA_CLUSTER_ID}" -c /opt/kafka/config/server.properties
  - Start only the broker (no ZooKeeper).
  - Create kafka user; chown relevant dirs; run daemon as kafka.
  - Put env in "$target/etc/profile.d/kafka.sh"; guard systemd unit creation behind a systemd presence check.

### 11) Dockerfile
- Problems:
  - apt-key is deprecated; missing apt cleanup; dev image lacks parity with scripts (cosign, container-structure-test).
- Changes:
  - Use signed-By entries in sources.list.d for Trivy repo; avoid apt-key add; clean apt caches/lists in same RUN.
  - Optionally install cosign and container-structure-test to align with scripts.

### 12) Makefile
- Problems:
  - REQUIRED_TOOLS missing gpg, cosign, trivy, container-structure-test; test assumes images preloaded; limited podman support; .PHONY incomplete.
- Changes:
  - Add missing tools to REQUIRED_TOOLS.
  - Add DOCKER_CMD ?= docker; allow override for podman.
  - In test target, auto-import tar if image not present:
    - $(DOCKER_CMD) import "$(DIST_DIR)/$$image_name/$$image_name.tar" "$$image_name"
  - Ensure all build targets are in .PHONY.
  - Align help/README with actual script paths (scripts/test.py, scripts/cosign.py).

### 13) README.rst
- Problems:
  - Wrong script paths; cosign usage implies local signing without registry; unclear image naming.
- Changes:
  - Update paths to scripts/cosign.py and scripts/test.py.
  - Clarify cosign typically needs a registry (unless using ocidir:/oci-archive:).
  - Document how built images are named/tagged and how tests reference them.

### 14) Vagrantfile
- Problems:
  - vmware_desktop-only; GUI enabled; no provisioning; ARM-specific box.
- Changes:
  - Add VirtualBox/Libvirt providers; disable GUI by default.
  - Provision Docker/Podman, make, debootstrap, curl, unzip, trivy, cosign, container-structure-test.
  - Consider a more universal Ubuntu base box.

---

## Reproducibility and security

- Prefer sha256 for all checksums; avoid md5.
- Pin versions and mirrors; avoid apt-get upgrade unless required.
- Verify download artifacts with checksums or GPG where available.
- Generate SBOMs (Syft) and sign/attach them with cosign; verify SBOMs in CI.
- Avoid curl | sh patterns; use authenticated repos and signature verification.
- Ensure recipes never modify the host—only operate on $target or within chroot "$target".

---

## CI/CD and pre-commit

- GitHub Actions:
  - Shell: shellcheck + shfmt.
  - Python: ruff + black + mypy; pytest with subprocess mocks.
  - Security: Trivy fs and (optionally) Grype; upload SARIF.
  - Tests: container-structure-test for each built image tar (load/import transiently if needed).
  - Signing/Verification (optional): cosign sign/verify behind protected secrets.
- Pre-commit:
  - Hooks for shfmt, shellcheck, ruff, black, end-of-file-fixer, trailing-whitespace.

---

## Developer UX (Makefile, README, Dockerfile, Vagrant)

- Makefile:
  - DOCKER_CMD toggle, better dependency checks, auto-import for tests, self-documenting help.
- README:
  - Correct script paths, clear prerequisites, registry requirements for cosign.
- Dockerfile:
  - Modern apt key management, proper cleanup, optional tool parity (cosign, container-structure-test).
- Vagrant:
  - Provider flexibility, non-GUI default, automated provisioning.

---

## Optional quality improvements

- Add CONTRIBUTING.md, SECURITY.md, CODEOWNERS, CHANGELOG with SemVer and signed tags.
- Add examples demonstrating end-to-end flows (build → scan → test → sign → verify).
- Provide troubleshooting tips for common errors (mount issues, SELinux, missing tools).
- Multi-arch support with buildx/qemu if needed.

---

## Files requested for deeper review

- test/*.yaml (ensure test configs match produced images).
- recipes/java/*.sh (verify paths/vars used by Kafka and chroot correctness).
- examples/* (docs vs behavior alignment).
