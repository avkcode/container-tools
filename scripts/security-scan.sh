#!/usr/bin/env bash

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

usage() {
    cat <<EOF
Usage: security-scan.sh --target <path> [--dist <dir>]

Options:
  --target PATH   Filesystem path to scan (required unless 'target' env is set)
  --dist   DIR    Output directory for results (default: ./dist)

Notes:
  - Returns exit code 1 when CRITICAL vulnerabilities are found.
  - Produces JSON output at <dist>/security_scan.json for CI.
EOF
}

main() {
    set -euo pipefail

    local SCAN_TARGET=""
    local DIST_DIR="./dist"

    # Parse args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target=*)
                SCAN_TARGET="${1#*=}"
                shift
                ;;
            --target)
                SCAN_TARGET="${2:-}"
                shift 2
                ;;
            --dist=*)
                DIST_DIR="${1#*=}"
                shift
                ;;
            --dist)
                DIST_DIR="${2:-./dist}"
                shift 2
                ;;
            -h|--help)
                usage
                return 0
                ;;
            *)
                # Ignore unknown args to remain compatible when sourced by other scripts
                shift
                ;;
        esac
    done

    # Fallback to environment variables if flags not provided
    if [[ -z "${SCAN_TARGET}" ]]; then
        SCAN_TARGET="${target:-}"
    fi
    if [[ -z "${DIST_DIR}" ]]; then
        DIST_DIR="${dist:-./dist}"
    fi

    # Check if trivy is installed
    if ! command -v trivy >/dev/null 2>&1; then
        warning "Trivy is not installed. Skipping security scan."
        warning "To enable security scanning, install trivy from https://github.com/aquasecurity/trivy"
        return 0
    fi

    # Validate target
    if [[ -z "${SCAN_TARGET}" ]]; then
        error "Target not specified. Use --target or set the 'target' environment variable."
        return 1
    fi

    # Ensure dist directory exists
    mkdir -p "${DIST_DIR}"

    # Perform the scan using Trivy exit codes directly
    info "Scanning with trivy (CRITICAL severity): ${SCAN_TARGET}"
    local rc=0
    set +e
    trivy fs --severity CRITICAL --exit-code 1 --no-progress \
        --format json --output "${DIST_DIR}/security_scan.json" \
        "${SCAN_TARGET}"
    rc=$?
    set -euo pipefail

    if [[ $rc -eq 0 ]]; then
        info "Security scan completed: no CRITICAL vulnerabilities."
    elif [[ $rc -eq 1 ]]; then
        error "Critical vulnerabilities found! See ${DIST_DIR}/security_scan.json for details."
    else
        error "Trivy scanning failed with exit code ${rc}. See ${DIST_DIR}/security_scan.json (if created) for details."
    fi

    return $rc
}

# Execute in a subshell to avoid leaking shell options when sourced
( main "$@" )
