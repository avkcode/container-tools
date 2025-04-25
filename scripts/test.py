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
            return "", ""
        result = subprocess.run(
            command,
            shell=True,
            check=False,  # Allow non-zero exit codes to capture stderr
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
        )
        logger.debug(f"Command stdout: {result.stdout.strip()}")
        logger.debug(f"Command stderr: {result.stderr.strip()}")
        return result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        logger.error(f"Command failed: {e}")
        raise

def validate_image(image_id):
    """Check if the Docker image exists locally."""
    try:
        # Use `docker inspect` to check if the image exists
        run_command(f"docker inspect --type=image {image_id}")
        return True
    except Exception:
        logger.warning(f"Docker image not found: {image_id}")
        return False

def validate_config_file(config_file):
    """Check if the YAML config file exists and has a valid extension."""
    if not config_file.exists():
        logger.error(f"Config file not found: {config_file}")
        return False
    if config_file.suffix not in (".yaml", ".yml"):
        logger.error(f"Invalid file type: {config_file}. Must be a .yaml or .yml file.")
        return False
    return True

def run_container_test(image_id, config_file, dry_run=False):
    """Run container-structure-test for the given image and config file."""
    try:
        logger.info(f"Testing image: {image_id} with config: {config_file}")

        # Construct the container-structure-test command
        test_cmd = [
            "container-structure-test",
            "test",
            "--image", image_id,
            "--config", str(config_file),
        ]

        # Execute the command
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(test_cmd)}")
            return

        stdout, stderr = run_command(" ".join(test_cmd), dry_run=dry_run)

        # Log the output
        if stdout:
            logger.info(f"Container Structure Test Output:\n{stdout}")
        if stderr:
            logger.error(f"Container Structure Test Errors:\n{stderr}")

        # Check the exit code
        result = subprocess.run(
            " ".join(test_cmd),
            shell=True,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode == 0:
            logger.info(f"Tests passed for image: {image_id} with config: {config_file}")
        else:
            logger.error(f"Tests failed for image: {image_id} with config: {config_file}")

    except Exception as e:
        logger.error(f"Failed to run tests for image: {image_id}. Error: {e}")
        raise

def main():
    parser = argparse.ArgumentParser(description="Run container-structure-tests for Docker images.")
    parser.add_argument(
        "--image",
        required=True,
        help="Docker image ID or tag to test.",
    )
    parser.add_argument(
        "--config",
        required=True,
        help="Path to a single YAML config file.",
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

    # Check if container-structure-test is installed
    try:
        run_command("container-structure-test version", dry_run=args.dry_run)
    except Exception:
        logger.error(
            "container-structure-test is not installed. To install, visit https://github.com/GoogleContainerTools/container-structure-test"
        )
        exit(1)

    # Validate the Docker image
    if not validate_image(args.image):
        logger.error(f"Docker image not found: {args.image}")
        exit(1)

    # Validate the YAML config file
    config_file = Path(args.config)
    if not validate_config_file(config_file):
        exit(1)

    # Run the test
    run_container_test(args.image, config_file, dry_run=args.dry_run)

    logger.info("All tests have been processed successfully.")

if __name__ == "__main__":
    import sys  # Import sys to check argument length
    main()
