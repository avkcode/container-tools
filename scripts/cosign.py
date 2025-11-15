#!/usr/bin/env python3

import os
import subprocess
import argparse
import sys
from pathlib import Path

# Import common utilities
from utils import logger, run_command, find_tar_files, check_program_installed

def is_docker_archive(tar_file):
    """Check if the tar file is a Docker archive (created with docker save)."""
    try:
        stdout, stderr = run_command(f"tar tf {tar_file}")
        return 'manifest.json' in stdout or 'repositories' in stdout
    except Exception:
        return False

def sign_image(tar_file, key=None, registry=None, dry_run=False, oci_ref_type="oci-archive"):
    """Sign a tar archive image using cosign.

    Behavior:
      - If --registry is provided:
          * load/import the image into Docker as <registry>/<name>:latest
          * push to the registry
          * sign the repo@digest returned from Docker after push
      - If no --registry is provided:
          * sign the local artifact using OCI references:
              - oci-archive:<tar_file> (default), or
              - ocidir:<path> when oci_ref_type='ocidir' and tar_file is a directory
    """
    try:
        image_name = Path(tar_file).stem
        final_tag = f"{registry}/{image_name}:latest" if registry else f"{image_name}:latest"

        if registry:
            # Load or import into Docker to push
            if is_docker_archive(tar_file):
                logger.info(f"Loading Docker archive: {tar_file}")
                stdout, stderr = run_command(f"docker load -i {tar_file}", dry_run=dry_run)

                loaded_tag = None
                for line in stdout.splitlines():
                    if "Loaded image:" in line:
                        loaded_tag = line.split("Loaded image:")[-1].strip()
                        break

                if not loaded_tag:
                    raise Exception("Could not determine loaded image tag from docker load output")

                logger.info(f"Tagging image: {loaded_tag} as: {final_tag}")
                run_command(f"docker tag {loaded_tag} {final_tag}", dry_run=dry_run)
            else:
                logger.info(f"Importing filesystem tarball: {tar_file} as {final_tag}")
                run_command(f"docker import {tar_file} {final_tag}", dry_run=dry_run)

            logger.info(f"Pushing image: {final_tag}")
            run_command(f"docker push {final_tag}", dry_run=dry_run)

            # Determine repo@digest from Docker
            logger.info(f"Getting repo digest for: {final_tag}")
            stdout, stderr = run_command(
                f"docker inspect {final_tag} --format='{{{{.RepoDigests}}}}'",
                dry_run=dry_run,
            )
            repo_digests_raw = stdout.strip().strip("[]")
            if not repo_digests_raw:
                raise Exception("No RepoDigests found after push; ensure the image was pushed successfully")

            entries = [d.strip("'\" ") for d in repo_digests_raw.split()]
            preferred = None
            for d in entries:
                if d.startswith(f"{registry}/") or d.startswith(registry):
                    preferred = d
                    break
            sign_reference = preferred or entries[0]
        else:
            # Local signing using OCI references
            if oci_ref_type == "ocidir":
                if not os.path.isdir(tar_file):
                    raise Exception("ocidir mode requires a directory path conforming to OCI layout")
                sign_reference = f"ocidir:{tar_file}"
            else:
                sign_reference = f"oci-archive:{tar_file}"

        logger.info(f"Signing reference: {sign_reference}")
        if key:
            sign_cmd = f"cosign sign --key {key} {sign_reference}"
        else:
            logger.warning("Using keyless signing. Ensure COSIGN_EXPERIMENTAL=1 is set.")
            sign_cmd = f"cosign sign {sign_reference}"

        run_command(sign_cmd, dry_run=dry_run)
        logger.info(f"Successfully signed: {sign_reference}")

    except Exception as e:
        logger.error(f"Failed to sign image: {tar_file}. Error: {e}")
        raise

def verify_image(reference, key=None, dry_run=False):
    """Verify a signed image reference using cosign.

    Reference can be:
      - repo:tag
      - repo@sha256:<digest>
      - ocidir:/path/to/oci-layout
      - oci-archive:/path/to/image.tar
    """
    if not reference:
        raise Exception("Verification requires a non-empty reference")

    logger.info(f"Verifying reference: {reference}")
    verify_cmd = f"cosign verify {'--key '+key+' ' if key else ''}{reference}"
    stdout, stderr = run_command(verify_cmd, dry_run=dry_run)
    if stdout:
        logger.info(f"Cosign verify output:\n{stdout}")
    if stderr:
        logger.warning(f"Cosign verify warnings:\n{stderr}")
    logger.info("Verification completed.")

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
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Verify a signed image reference instead of signing tar files.",
    )
    parser.add_argument(
        "--reference",
        help="Image reference to verify (repo:tag, repo@digest, ocidir:/path, or oci-archive:/path).",
    )
    parser.add_argument(
        "--oci-ref-type",
        choices=["oci-archive", "ocidir"],
        default="oci-archive",
        help="OCI reference type for local signing when --registry is not provided.",
    )

    # Parse arguments
    args = parser.parse_args()

    # Show help if no arguments are provided
    if len(sys.argv) == 1:  # No arguments provided
        parser.print_help()
        return

    # Cosign must be available for both signing and verifying
    if not check_program_installed("cosign", "https://docs.sigstore.dev/cosign/installation/"):
        exit(1)

    # Verification mode
    if args.verify:
        if not args.reference:
            logger.error("Verification requires --reference set to repo:tag, repo@digest, ocidir:/path or oci-archive:/path.")
            exit(1)
        verify_image(args.reference, args.key, args.dry_run)
        return

    # Signing mode
    if args.registry:
        # Docker is required when pushing to a registry
        if not check_program_installed("docker", "https://docs.docker.com/engine/install/"):
            exit(1)

    # Find all .tar files in the specified directory
    tar_files = find_tar_files(args.directory)
    if not tar_files:
        logger.info("No .tar files found. Exiting.")
        return

    # Sign each tar file sequentially
    for tar_file in tar_files:
        sign_image(tar_file, args.key, args.registry, args.dry_run, args.oci_ref_type)

    logger.info("All images have been processed successfully.")

if __name__ == "__main__":
    main()
