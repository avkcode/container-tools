#!/usr/bin/env python3

import os
import argparse
from pathlib import Path

# Import common utilities
from utils import logger, run_command, check_program_installed

def _parse_run_result(result):
    """Normalize run_command return into (stdout, stderr, rc) with rc as int (0=success, 1=error)."""
    stdout = ""
    stderr = ""
    rc = None
    try:
        # Unpack common shapes from utils.run_command
        if isinstance(result, tuple):
            if len(result) == 3:
                stdout, stderr, rc = result
            elif len(result) == 2:
                stdout, rc = result
                stderr = ""
            else:
                rc = 1
        else:
            rc = getattr(result, "returncode", None)
            stdout = getattr(result, "stdout", "")
            stderr = getattr(result, "stderr", "")

        # Normalize rc to int semantics (0=success)
        if isinstance(rc, bool):
            rc = 0 if rc is True else 1
        elif isinstance(rc, str):
            s = rc.strip().lower()
            try:
                rc = int(s)
            except Exception:
                if s in ("0", "ok", "pass", "passed", "success", "true"):
                    rc = 0
                elif s in ("1", "error", "fail", "failed", "failure", "false"):
                    rc = 1
                else:
                    rc = 1
        if rc is None:
            rc = 1

        # Collapse any non-zero to 1 for downstream checks
        rc = 0 if rc == 0 else 1
    except Exception:
        stdout, stderr, rc = "", "", 1
    return stdout, stderr, rc

def normalize_image_ref(image_id):
    """Return an image reference, adding ':latest' if no explicit tag or digest is present."""
    try:
        # If digest is used, keep as-is
        if "@" in image_id:
            return image_id
        last_slash = image_id.rfind("/")
        last_colon = image_id.rfind(":")
        has_tag = last_colon > last_slash
        if not has_tag:
            return f"{image_id}:latest"
        return image_id
    except Exception:
        # On any parsing error, just return original
        return image_id

def validate_image(image_id):
    """Check if the Docker image exists locally. Falls back to :latest if no tag is specified."""
    try:
        result = run_command(["docker", "inspect", "--type=image", image_id])
        stdout, stderr, rc = _parse_run_result(result)
        if rc == 0:
            return True

        # If inspect failed and the image reference has no explicit tag, try ":latest"
        normalized = normalize_image_ref(image_id)
        if normalized != image_id:
            logger.info(f"Image '{image_id}' not found, retrying with default tag: '{normalized}'")
            result = run_command(["docker", "inspect", "--type=image", normalized])
            stdout, stderr, rc = _parse_run_result(result)
            if rc == 0:
                return True

        logger.warning(f"Docker image not found: {image_id}")
        return False
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
        normalized_image = normalize_image_ref(image_id)
        # Log normalized so users see the exact reference used
        logger.info(f"Testing image: {normalized_image} with config: {config_file}")

        # Construct the container-structure-test command
        test_cmd = [
            "container-structure-test",
            "test",
            "--image", normalized_image,
            "--config", str(config_file),
        ]

        # Execute the command once
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {' '.join(test_cmd)}")
            return

        result = run_command(test_cmd, dry_run=dry_run)
        stdout, stderr, rc = _parse_run_result(result)

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

    # Normalize image reference, but don't hard-fail on preflight inspect; container-structure-test will surface real errors
    normalized_image = normalize_image_ref(args.image)
    if not validate_image(normalized_image):
        logger.warning(f"Docker image not found via preflight inspect: {normalized_image}. Proceeding to run tests anyway.")

    # Validate the YAML config file
    config_file = Path(args.config)
    if not validate_config_file(config_file):
        exit(1)

    # Run the test
    run_container_test(normalized_image, config_file, dry_run=args.dry_run)

    logger.info("All tests have been processed successfully.")

if __name__ == "__main__":
    import sys  # Import sys to check argument length
    main()
