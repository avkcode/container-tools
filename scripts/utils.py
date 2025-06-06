#!/usr/bin/env python3

import os
import subprocess
import logging
from pathlib import Path

def setup_logging():
    """Configure and return a logger instance."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.StreamHandler()],
    )
    return logging.getLogger(__name__)

# Create a global logger instance
logger = setup_logging()

def run_command(command, cwd=None, dry_run=False):
    """Run a shell command and return its output.
    
    Args:
        command: The command to run (string or list)
        cwd: Working directory to run the command in
        dry_run: If True, only log the command without executing
        
    Returns:
        stdout: Standard output from the command
        stderr: Standard error from the command (if capture_stderr=True)
    """
    try:
        # Convert command list to string if needed
        if isinstance(command, list):
            cmd_str = " ".join(command)
        else:
            cmd_str = command
            
        logger.debug(f"Running command: {cmd_str}")
        
        if dry_run:
            logger.info(f"[Dry Run] Skipping execution of: {cmd_str}")
            return "", ""
            
        result = subprocess.run(
            cmd_str,
            shell=True,
            check=False,  # Don't raise exception on non-zero exit
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
        )
        
        if result.returncode != 0:
            logger.warning(f"Command exited with code {result.returncode}: {cmd_str}")
            logger.warning(f"Error output: {result.stderr.strip()}")
        
        return result.stdout.strip(), result.stderr.strip()
        
    except Exception as e:
        logger.error(f"Command failed: {e}")
        raise

def find_tar_files(directory):
    """Find all .tar files in the specified directory.
    
    Args:
        directory: Path to search for .tar files
        
    Returns:
        List of Path objects for .tar files
    """
    tar_files = list(Path(directory).rglob("*.tar"))
    if not tar_files:
        logger.warning(f"No .tar files found in directory: {directory}")
    return tar_files

def check_program_installed(program_name, install_url=None):
    """Check if a program is installed and available in PATH.
    
    Args:
        program_name: Name of the program to check
        install_url: URL with installation instructions (optional)
        
    Returns:
        bool: True if installed, False otherwise
    """
    try:
        subprocess.run(
            ["which", program_name],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return True
    except subprocess.CalledProcessError:
        if install_url:
            logger.error(
                f"{program_name} is not installed. "
                f"To install {program_name}, visit {install_url}"
            )
        else:
            logger.error(f"{program_name} is not installed.")
        return False
