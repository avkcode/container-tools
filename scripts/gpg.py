#!/usr/bin/env python3

import os
import subprocess
import argparse
from pathlib import Path

# Import common utilities
from utils import logger, run_command, find_tar_files, check_program_installed

def is_valid_tar_file(tar_file):
    """Check if the file is a valid tar archive."""
    try:
        # Use `tar tf` to list contents; if it fails, it's not a valid tar file
        stdout, stderr = run_command(f"tar tf {tar_file}")
        if stderr:
            logger.warning(f"File is not a valid tar archive: {tar_file}")
            return False
        return True
    except Exception:
        logger.warning(f"File is not a valid tar archive: {tar_file}")
        return False

def sign_tarball_with_gpg(tar_file, gpg_key_id, passphrase=None, dry_run=False):
    """Sign a tarball using GPG."""
    try:
        signature_file = f"{tar_file}.asc"  # Default to .asc for ASCII-armored signatures
        logger.info(f"Signing tarball: {tar_file} -> Signature: {signature_file}")

        # Check if the signature file already exists
        if Path(signature_file).exists():
            overwrite = input(f"File '{signature_file}' exists. Overwrite? (y/N) ").strip().lower()
            if overwrite != "y":
                logger.info(f"Skipping signing of {tar_file}.")
                return

        # Construct the GPG signing command
        gpg_cmd = ["gpg", "--detach-sign", "--armor"]
        if gpg_key_id:
            gpg_cmd.extend(["--local-user", gpg_key_id])
        if passphrase:
            gpg_cmd.extend(["--batch", "--pinentry-mode", "loopback", "--passphrase", passphrase])

        gpg_cmd.append(str(tar_file))

        # Execute the GPG command
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(gpg_cmd)}")
        else:
            result = subprocess.run(
                gpg_cmd,
                check=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if result.returncode != 0:
                raise Exception(f"GPG signing failed: {result.stderr}")

        logger.info(f"Successfully signed tarball: {tar_file}")
        logger.info(f"Signature saved to: {signature_file}")

    except Exception as e:
        logger.error(f"Failed to sign tarball: {tar_file}. Error: {e}")
        raise

def verify_tarball_with_gpg(tar_file, sig_file, dry_run=False):
    """Verify the signature of a tarball using GPG."""
    try:
        if not Path(sig_file).exists():
            logger.warning(f"Signature file not found: {sig_file}")
            return False

        logger.info(f"Verifying tarball: {tar_file} against signature: {sig_file}")

        # Construct the GPG verification command
        gpg_cmd = ["gpg", "--verify", str(sig_file), str(tar_file)]

        # Execute the GPG command
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(gpg_cmd)}")
        else:
            result = subprocess.run(
                gpg_cmd,
                check=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if result.returncode == 0:
                logger.info(f"Verification successful: {tar_file}")
                return True
            else:
                logger.error(f"Verification failed: {tar_file}")
                return False

    except Exception as e:
        logger.error(f"Failed to verify tarball: {tar_file}. Error: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Sign or verify tarball archives using GPG.")
    parser.add_argument(
        "--directory",
        default="dist/",
        help="Directory or file containing tar archives to process (default: dist/).",
    )
    parser.add_argument(
        "--gpg-key-id",
        help="GPG key ID to use for signing (required for signing).",
    )
    parser.add_argument(
        "--passphrase",
        help="Passphrase for the GPG key (optional, will prompt if not provided).",
    )
    parser.add_argument(
        "--sig-file",
        help="Path to the signature file (.asc or .sig) for verification (optional).",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Verify signatures instead of signing.",
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

    # Check if GPG is installed
    if not check_program_installed("gpg", "https://gnupg.org/download/"):
        exit(1)

    # Determine if the input is a file or directory
    path = Path(args.directory)
    if path.is_file() and path.suffix == ".tar":
        tar_files = [path]  # Treat as a single file
    elif path.is_dir():
        tar_files = find_tar_files(path)  # Search for .tar files in the directory
    else:
        logger.error(f"Invalid input: {args.directory} is neither a .tar file nor a directory.")
        exit(1)

    if not tar_files:
        logger.info("No .tar files found. Exiting.")
        return

    # Process each tar file sequentially
    for tar_file in tar_files:
        if not is_valid_tar_file(tar_file):
            logger.warning(f"Skipping invalid tar file: {tar_file}")
            continue

        if args.verify:
            # Use the provided signature file or default to <tar_file>.asc
            sig_file = args.sig_file or f"{tar_file}.asc"
            if not Path(sig_file).exists():
                logger.warning(f"Signature file not found: {sig_file}. Skipping verification.")
                continue
            verify_tarball_with_gpg(tar_file, sig_file, dry_run=args.dry_run)
        else:
            if not args.gpg_key_id:
                logger.error("GPG key ID (--gpg-key-id) is required for signing.")
                exit(1)
            sign_tarball_with_gpg(
                tar_file,
                gpg_key_id=args.gpg_key_id,
                passphrase=args.passphrase,
                dry_run=args.dry_run,
            )

    logger.info("All tarballs have been processed successfully.")

if __name__ == "__main__":
    import sys  # Import sys to check argument length
    main()
