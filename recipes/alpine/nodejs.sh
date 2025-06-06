#!/usr/bin/env bash

# Exit on error
set -e

# Configure logging
info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
}

# Default Node.js version
NODEJS_VERSION="20.11.1"

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --rootfs)
            ROOTFS="$2"
            shift 2
            ;;
        --nodejs-version)
            NODEJS_VERSION="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if rootfs is provided
if [ -z "${ROOTFS}" ]; then
    error "Rootfs directory not specified. Please use --rootfs option."
    exit 1
fi

info "Installing Node.js ${NODEJS_VERSION} in ${ROOTFS}"

# Create a chroot environment
mkdir -p "${ROOTFS}/proc"
mkdir -p "${ROOTFS}/sys"
mkdir -p "${ROOTFS}/dev"
mount -t proc /proc "${ROOTFS}/proc"
mount -t sysfs /sys "${ROOTFS}/sys"
mount --bind /dev "${ROOTFS}/dev"

# Install Node.js
chroot "${ROOTFS}" /bin/sh -c "apk add --no-cache nodejs npm"

# Verify installation
NODE_VERSION=$(chroot "${ROOTFS}" /bin/sh -c "node --version 2>/dev/null || echo 'Not installed'")
info "Node.js version installed: ${NODE_VERSION}"

NPM_VERSION=$(chroot "${ROOTFS}" /bin/sh -c "npm --version 2>/dev/null || echo 'Not installed'")
info "NPM version installed: ${NPM_VERSION}"

# Clean up mounts
umount "${ROOTFS}/proc"
umount "${ROOTFS}/sys"
umount "${ROOTFS}/dev"

info "Node.js installation completed successfully"
