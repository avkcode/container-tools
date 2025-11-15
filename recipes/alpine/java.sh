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

# Default Java version
JAVA_VERSION="17"

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --rootfs)
            ROOTFS="$2"
            shift 2
            ;;
        --java-version)
            JAVA_VERSION="$2"
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

info "Installing OpenJDK ${JAVA_VERSION} in ${ROOTFS}"

# Create a chroot environment
mkdir -p "${ROOTFS}/proc"
mkdir -p "${ROOTFS}/sys"
mkdir -p "${ROOTFS}/dev"
mount -t proc /proc "${ROOTFS}/proc"
mount -t sysfs /sys "${ROOTFS}/sys"
mount --bind /dev "${ROOTFS}/dev"

# Install OpenJDK
case "${JAVA_VERSION}" in
    8)
        chroot "${ROOTFS}" /bin/sh -c "apk add --no-cache openjdk8"
        ;;
    11)
        chroot "${ROOTFS}" /bin/sh -c "apk add --no-cache openjdk11"
        ;;
    17)
        chroot "${ROOTFS}" /bin/sh -c "apk add --no-cache openjdk17"
        ;;
    *)
        error "Unsupported Java version: ${JAVA_VERSION}. Supported versions: 8, 11, 17"
        umount "${ROOTFS}/proc"
        umount "${ROOTFS}/sys"
        umount "${ROOTFS}/dev"
        exit 1
        ;;
esac

# Set JAVA_HOME environment variable
chroot "${ROOTFS}" /bin/sh -c "echo 'export JAVA_HOME=/usr/lib/jvm/default-jvm' >> /etc/profile.d/java.sh"
chroot "${ROOTFS}" /bin/sh -c "chmod +x /etc/profile.d/java.sh"

# Verify installation
JAVA_VERSION_INSTALLED=$(chroot "${ROOTFS}" /bin/sh -c "java -version 2>&1 || echo 'Not installed'")
info "Java version installed: ${JAVA_VERSION_INSTALLED}"

# Clean up mounts
umount "${ROOTFS}/proc"
umount "${ROOTFS}/sys"
umount "${ROOTFS}/dev"

info "Java installation completed successfully"
