#!/usr/bin/env python3

import argparse
import os
import sys
import tarfile
from pathlib import Path

# Ensure local scripts directory is in import path
sys.path.append(str(Path(__file__).resolve().parent))

from utils import logger, run_command, check_program_installed
from gpg import sign_tarball_with_gpg, is_valid_tar_file


def detect_archive_type(tar_path: Path) -> str:
    """
    Detect whether a tarball is an OCI archive, Docker archive, or plain rootfs.
    - OCI archive: contains index.json and oci-layout
    - Docker archive: contains manifest.json
    - Rootfs: neither of the above (a flat filesystem tar)
    """
    try:
        with tarfile.open(tar_path, "r:*") as tf:
            names = {m.name for m in tf.getmembers()}
        if "index.json" in names and "oci-layout" in names:
            return "oci-archive"
        if "manifest.json" in names:
            return "docker-archive"
    except Exception as e:
        logger.debug(f"Failed to inspect tar for archive type: {e}")
    return "rootfs"


def import_image(tar_file, image_name, transport="auto", insecure_policy=True, dry_run=False):
    tar_path = Path(tar_file)
    if not tar_path.exists():
        logger.error(f"Tar file not found: {tar_file}")
        return False
    if not is_valid_tar_file(tar_path):
        logger.error(f"Invalid tar file: {tar_file}")
        return False

    # Auto-detect archive type if requested
    if transport == "auto":
        transport = detect_archive_type(tar_path)

    if transport in ("oci-archive", "docker-archive"):
        # Use skopeo to import OCI/Docker archives
        dest = f"docker://{image_name}"
        src = f"{transport}:{tar_path}"

        cmd = ["skopeo", "copy"]
        if insecure_policy:
            cmd.append("--insecure-policy")
        cmd.extend([src, dest])

        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(cmd)}")
            return True

        stdout, stderr, rc = run_command(cmd)
        if rc != 0:
            logger.error(f"skopeo copy failed: {stderr or stdout}")
            return False

        logger.info(f"Imported image {image_name} from {tar_path} via skopeo ({transport})")
        return True
    else:
        # Fall back to docker import for plain rootfs tarballs
        cmd = ["docker", "import", str(tar_path), image_name]

        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(cmd)}")
            return True

        stdout, stderr, rc = run_command(cmd)
        if rc != 0:
            logger.error(f"docker import failed: {stderr or stdout}")
            return False

        logger.info(f"Imported image {image_name} from {tar_path} via docker import (rootfs)")
        return True


def main():
    parser = argparse.ArgumentParser(description="Import an image tarball with skopeo and sign it with GPG.")
    parser.add_argument("--tar-file", required=True, help="Path to the image tarball (*.tar)")
    parser.add_argument("--image-name", required=True, help="Destination image name (e.g., repo/name:tag)")
    parser.add_argument("--transport", default="auto", choices=["auto", "docker-archive", "oci-archive"], help="Source tar transport type")
    parser.add_argument("--gpg-key-id", help="GPG key ID for signing (required to sign)")
    parser.add_argument("--passphrase", help="GPG key passphrase (optional)")
    parser.add_argument("--dry-run", action="store_true", help="Perform a dry run without executing commands")
    args = parser.parse_args()

    # Check required programs
    if not check_program_installed("gpg", "https://gnupg.org/download/"):
        sys.exit(1)

    # Determine archive type and check for required container tooling
    tar_path = Path(args.tar_file)
    arch_type = detect_archive_type(tar_path) if args.transport == "auto" else args.transport
    if arch_type in ("oci-archive", "docker-archive"):
        if not check_program_installed("skopeo", "https://github.com/containers/skopeo"):
            sys.exit(1)
    else:
        if not check_program_installed("docker", "https://docs.docker.com/get-docker/"):
            sys.exit(1)

    # Import image using appropriate method
    imported = import_image(args.tar_file, args.image_name, transport=arch_type, dry_run=args.dry_run)
    if not imported:
        sys.exit(1)

    # Sign the tarball using GPG (skipped in GitHub Actions)
    if os.environ.get("GITHUB_ACTIONS") == "true":
        logger.info("Detected GitHub Actions; skipping GPG signing in CI.")
    elif args.gpg_key_id:
        sign_tarball_with_gpg(
            args.tar_file,
            gpg_key_id=args.gpg_key_id,
            passphrase=args.passphrase,
            dry_run=args.dry_run,
            force=True,
        )
    else:
        logger.info("No --gpg-key-id provided; skipping GPG signing.")

if __name__ == "__main__":
    main()
