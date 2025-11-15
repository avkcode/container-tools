#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path

# Ensure local scripts directory is in import path
sys.path.append(str(Path(__file__).resolve().parent))

from utils import logger, run_command, check_program_installed
from gpg import sign_tarball_with_gpg, is_valid_tar_file


def import_image(tar_file, image_name, transport="docker-archive", insecure_policy=True, dry_run=False):
    tar_path = Path(tar_file)
    if not tar_path.exists():
        logger.error(f"Tar file not found: {tar_file}")
        return False
    if not is_valid_tar_file(tar_path):
        logger.error(f"Invalid tar file: {tar_file}")
        return False

    # Use correct skopeo destination transport prefix
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

    logger.info(f"Imported image {image_name} from {tar_path}")
    return True


def main():
    parser = argparse.ArgumentParser(description="Import an image tarball with skopeo and sign it with GPG.")
    parser.add_argument("--tar-file", required=True, help="Path to the image tarball (*.tar)")
    parser.add_argument("--image-name", required=True, help="Destination image name (e.g., repo/name:tag)")
    parser.add_argument("--transport", default="docker-archive", choices=["docker-archive", "oci-archive"], help="Source tar transport type")
    parser.add_argument("--gpg-key-id", help="GPG key ID for signing (required to sign)")
    parser.add_argument("--passphrase", help="GPG key passphrase (optional)")
    parser.add_argument("--dry-run", action="store_true", help="Perform a dry run without executing commands")
    args = parser.parse_args()

    # Check required programs
    if not check_program_installed("skopeo", "https://github.com/containers/skopeo"):
        sys.exit(1)
    if not check_program_installed("gpg", "https://gnupg.org/download/"):
        sys.exit(1)

    # Import image using skopeo with correct docker:// destination prefix
    imported = import_image(args.tar_file, args.image_name, transport=args.transport, dry_run=args.dry_run)
    if not imported:
        sys.exit(1)

    # Sign the tarball using GPG
    if args.gpg_key_id:
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
