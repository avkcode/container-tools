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

def is_docker_archive(tar_file):
    """Check if the tar file is a Docker archive (created with docker save)."""
    try:
        contents = run_command(f"tar tf {tar_file}")
        return 'manifest.json' in contents or 'repositories' in contents
    except Exception:
        return False

def sign_image(tar_file, key=None, registry=None, dry_run=False):
    """Sign a tar archive image using cosign."""
    try:
        image_name = Path(tar_file).stem
        temp_tag = f"temp_{image_name}:latest"
        final_tag = f"{registry}/{image_name}:latest" if registry else f"{image_name}:latest"

        # Determine if this is a Docker archive or filesystem tarball
        if is_docker_archive(tar_file):
            logger.info(f"Loading Docker archive: {tar_file}")
            run_command(f"docker load -i {tar_file}", dry_run=dry_run)
            
            # Get the loaded image tag
            load_output = run_command(f"docker load -i {tar_file}", dry_run=dry_run)
            loaded_tag = None
            for line in load_output.split('\n'):
                if 'Loaded image:' in line:
                    loaded_tag = line.split('Loaded image:')[-1].strip()
                    break
            
            if not loaded_tag:
                raise Exception("Could not determine loaded image tag")
            
            # Tag the image with our desired name
            logger.info(f"Tagging image: {loaded_tag} as: {final_tag}")
            run_command(f"docker tag {loaded_tag} {final_tag}", dry_run=dry_run)
        else:
            logger.info(f"Importing filesystem tarball: {tar_file} as {final_tag}")
            run_command(f"docker import {tar_file} {final_tag}", dry_run=dry_run)

        # Push to registry if specified
        if registry:
            logger.info(f"Pushing image: {final_tag}")
            run_command(f"docker push {final_tag}", dry_run=dry_run)
        
        # Get the image digest
        logger.info(f"Getting digest for image: {final_tag}")
        inspect_output = run_command(f"docker inspect {final_tag} --format='{{{{.RepoDigests}}}}'", dry_run=dry_run)
        if not inspect_output or inspect_output == '[]':
            # If no digest available (local image not pushed), create one
            if registry:
                raise Exception("Image was not properly pushed to registry")
            else:
                # For local images, we'll use the image ID
                inspect_output = run_command(f"docker inspect {final_tag} --format='{{{{.Id}}}}'", dry_run=dry_run)
                image_reference = inspect_output.strip()
        else:
            # Extract the digest from the RepoDigests output
            image_reference = inspect_output.strip("[]'").split('@')[-1]

        # Sign the image using cosign with the digest
        logger.info(f"Signing image digest: {image_reference}")
        if key:
            sign_cmd = f"cosign sign --key {key} {image_reference}"
        else:
            logger.warning("Using keyless signing. Ensure COSIGN_EXPERIMENTAL=1 is set.")
            sign_cmd = f"cosign sign {image_reference}"
        
        run_command(sign_cmd, dry_run=dry_run)
        
        logger.info(f"Successfully signed image: {image_reference}")
        
    except Exception as e:
        logger.error(f"Failed to sign image: {tar_file}. Error: {e}")
        raise

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
