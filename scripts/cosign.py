#!/usr/bin/env python3

import os
import subprocess
import argparse
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

def run_command(command, cwd=None, dry_run=False):
    """Run a shell command and return its output."""
    try:
        logger.debug(f"Running command: {command}")
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {command}")
            return ""
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {e.stderr}")
        raise

def find_tar_files(directory):
    """Find all .tar files in the specified directory."""
    tar_files = list(Path(directory).rglob("*.tar"))
    if not tar_files:
        logger.warning(f"No .tar files found in directory: {directory}")
    return tar_files

def sign_image(tar_file, key=None, registry=None, dry_run=False):
    """Sign a tar archive image using cosign."""
    try:
        # Load the tar archive into Docker as an image
        image_name = tar_file.stem
        logger.info(f"Importing tar file: {tar_file} as image: {image_name}")
        run_command(f"docker import {tar_file} {image_name}", dry_run=dry_run)

        # Sign the image using cosign
        logger.info(f"Signing image: {image_name}")
        if key:
            run_command(f"cosign sign --key {key} {image_name}", dry_run=dry_run)
        else:
            run_command(f"cosign sign {image_name}", dry_run=dry_run)

        # Push the signed image to the registry if specified
        if registry:
            tagged_image = f"{registry}/{image_name}"
            logger.info(f"Tagging image: {image_name} as: {tagged_image}")
            run_command(f"docker tag {image_name} {tagged_image}", dry_run=dry_run)
            logger.info(f"Pushing image: {tagged_image}")
            run_command(f"docker push {tagged_image}", dry_run=dry_run)
            run_command(f"cosign attach signature --signature {tagged_image}", dry_run=dry_run)

        logger.info(f"Successfully signed image: {image_name}")
    except Exception as e:
        logger.error(f"Failed to sign image: {tar_file}. Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Sign tar archive images using cosign.")
    parser.add_argument(
        "--directory",
        default="dist/",
        help="Directory containing tar archives to sign (default: dist/).",
    )
    parser.add_argument(
        "--key", help="Private key for signing (optional, defaults to cosign's keyless mode)."
    )
    parser.add_argument(
        "--registry", help="Push signed images to a container registry (optional)."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Perform a dry run without executing commands.",
    )

    # Parse arguments
    args = parser.parse_args()

    # Show help if no arguments are provided
    if len(sys.argv) == 1:  # No arguments provided
        parser.print_help()
        return

    # Check if cosign is installed
    try:
        run_command("cosign version", dry_run=args.dry_run)
    except Exception:
        logger.error(
            "Cosign is not installed. To install cosign, visit https://docs.sigstore.dev/cosign/installation/"
        )
        exit(1)

    # Find all .tar files in the specified directory
    tar_files = find_tar_files(args.directory)
    if not tar_files:
        logger.info("No .tar files found. Exiting.")
        return

    # Sign each tar file sequentially
    for tar_file in tar_files:
        sign_image(tar_file, args.key, args.registry, args.dry_run)

    logger.info("All images have been processed successfully.")

if __name__ == "__main__":
    import sys  # Import sys to check argument length
    main()
