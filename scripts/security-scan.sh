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
Usage: security-scan.sh --target <path> [--dist <dir>] [--skip]

Options:
  --target PATH   Filesystem path to scan (required unless 'target' env is set)
  --dist   DIR    Output directory for results (default: ./dist)
  --skip          Skip the scan and exit successfully (can also set CT_SKIP_SECURITY_SCAN=1)

Environment:
  CT_SKIP_SECURITY_SCAN   When set to 1/true/yes, the scan is skipped.

Notes:
  - Returns exit code 1 when CRITICAL vulnerabilities are found.
  - Produces JSON output at <dist>/security_scan.json for CI.
EOF
}

main() {
    set -euo pipefail

    local SCAN_TARGET=""
    local DIST_DIR="./dist"
    local SKIP="${CT_SKIP_SECURITY_SCAN:-}"
    local USE_TRIVY_CONTAINER=""

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
            -s|--skip)
                SKIP="1"
                shift
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

    # Optional: allow disabling the scan entirely
    if [[ -n "${SKIP}" ]]; then
        case "${SKIP,,}" in
            1|true|yes)
                warning "Security scan disabled via CT_SKIP_SECURITY_SCAN or --skip. Skipping."
                return 0
                ;;
        esac
    fi

    # Check if trivy is installed, otherwise fall back to official container if Docker is available
    if ! command -v trivy >/dev/null 2>&1; then
        if command -v docker >/dev/null 2>&1; then
            info "Trivy not installed; will use the official aquasec/trivy container."
            USE_TRIVY_CONTAINER="1"
        else
            warning "Trivy is not installed and Docker is unavailable. Skipping security scan."
            warning "To enable security scanning, install trivy from https://github.com/aquasecurity/trivy or install Docker to use the Trivy container."
            return 0
        fi
    fi

    # Validate target
    if [[ -z "${SCAN_TARGET}" ]]; then
        error "Target not specified. Use --target or set the 'target' environment variable."
        return 1
    fi

    # Ensure dist directory exists
    mkdir -p "${DIST_DIR}"

    # Perform the scan using Trivy exit codes directly
    local rc=0
    set +e
    if [[ -n "${USE_TRIVY_CONTAINER:-}" ]]; then
        info "Scanning with Trivy container (CRITICAL severity): ${SCAN_TARGET}"
        # Resolve absolute paths for Docker volume mounts
        local TARGET_ABS="${SCAN_TARGET}"
        [[ "${TARGET_ABS}" = /* ]] || TARGET_ABS="${PWD}/${TARGET_ABS}"
        local DIST_ABS="${DIST_DIR}"
        [[ "${DIST_ABS}" = /* ]] || DIST_ABS="${PWD}/${DIST_ABS}"

        docker run --rm \
            -v "${TARGET_ABS}:/project:ro" \
            -v "${DIST_ABS}:/out" \
            aquasec/trivy:latest fs --severity CRITICAL --exit-code 1 --no-progress \
                --format json --output /out/security_scan.json \
                /project
        rc=$?
    else
        info "Scanning with trivy (CRITICAL severity): ${SCAN_TARGET}"
        trivy fs --severity CRITICAL --exit-code 1 --no-progress \
            --format json --output "${DIST_DIR}/security_scan.json" \
            "${SCAN_TARGET}"
        rc=$?
    fi
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
