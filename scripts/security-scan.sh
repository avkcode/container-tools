#!/usr/bin/env bash

set -e

# Configure logging
info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >&2
}

# Check if trivy is installed
if ! command -v trivy &> /dev/null; then
    warning "Trivy is not installed. Skipping security scan."
    warning "To enable security scanning, install trivy from https://github.com/aquasecurity/trivy"
    exit 0
fi

# Check if target is provided
if [ -z "$target" ]; then
    error "Target not specified. Please set the 'target' variable."
    exit 1
fi

# Check if dist directory exists
if [ -z "$dist" ]; then
    dist="./dist"
    info "No dist directory specified, using default: $dist"
fi

# Create dist directory if it doesn't exist
mkdir -p "$dist"

# Update vulnerability database
info "Updating vulnerability database"
trivy --download-db-only

# Perform the scan
info "Scanning with trivy: $target"
trivy fs --no-progress "$target" 2>&1 | tee "${dist}/security_scan.txt"

# Check for critical vulnerabilities
if grep -q "CRITICAL: [1-9]" "${dist}/security_scan.txt"; then
    error "Critical vulnerabilities found! See ${dist}/security_scan.txt for details."
    exit 1
fi

info "Security scan completed. Results saved to ${dist}/security_scan.txt"
