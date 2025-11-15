#!/usr/bin/env python3

import os
import argparse
from pathlib import Path

# Import common utilities
from utils import logger, run_command, check_program_installed

def validate_image(image_id):
    """Check if the Docker image exists locally."""
    try:
        result = run_command(["docker", "inspect", "--type=image", image_id])
        try:
            stdout, stderr, rc = result
        except ValueError:
            stdout, rc = result
            stderr = ""
        if rc != 0:
            logger.warning(f"Docker image not found: {image_id}")
            return False
        return True
    except Exception as e:
        logger.warning(f"Error inspecting Docker image {image_id}: {e}")
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

        # Execute the command once
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(test_cmd)}")
            return

        result = run_command(test_cmd, dry_run=dry_run)
        try:
            stdout, stderr, rc = result
        except ValueError:
            stdout, rc = result
            stderr = ""

        # Log the output
        if stdout:
            logger.info(f"Container Structure Test Output:\n{stdout}")
        if stderr:
            logger.error(f"Container Structure Test Errors:\n{stderr}")

        if rc == 0:
            logger.info(f"Tests passed for image: {image_id} with config: {config_file}")
        else:
            logger.error(f"Tests failed for image: {image_id} with config: {config_file}")
            raise RuntimeError(f"container-structure-test exited with code {rc}")

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
    if not check_program_installed("container-structure-test", 
                                  "https://github.com/GoogleContainerTools/container-structure-test"):
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
