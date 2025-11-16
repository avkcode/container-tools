#!/usr/bin/env bash
# Install NVIDIA Container Toolkit components inside the Debian rootfs.
# This enables GPU-aware runtimes and the nvidia-ctk utility inside the image.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Helper to check if a package is installed
pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Ensure prerequisites
need_pre_reqs=()
for p in ca-certificates curl gnupg; do
  if ! pkg_installed "$p"; then
    need_pre_reqs+=("$p")
  fi
done
if [ "${#need_pre_reqs[@]}" -gt 0 ]; then
  apt-get update
  apt-get install -y --no-install-recommends "${need_pre_reqs[@]}"
fi

# Configure NVIDIA libnvidia-container repository and keyring (idempotent)
KEYRING_PATH="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
LIST_PATH="/etc/apt/sources.list.d/nvidia-container-toolkit.list"

if [ ! -f "$KEYRING_PATH" ]; then
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o "$KEYRING_PATH"
  chmod 0644 "$KEYRING_PATH"
fi

if [ ! -f "$LIST_PATH" ]; then
  distribution="debian11"
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [ -n "${ID:-}" ] && [ -n "${VERSION_ID:-}" ]; then
      distribution="${ID}${VERSION_ID}"
    fi
  fi
  curl -fsSL "https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list" \
    | sed "s#deb https://#deb [signed-by=${KEYRING_PATH}] https://#g" \
    | tee "$LIST_PATH" >/dev/null
  chmod 0644 "$LIST_PATH"
fi

# Install NVIDIA container toolkit packages if not already present
if ! command -v nvidia-ctk >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends \
    nvidia-container-toolkit \
    nvidia-container-runtime \
    libnvidia-container1 \
    libnvidia-container-tools \
    nvidia-container-toolkit-base || true
fi

# Clean up APT caches to keep image small
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "NVIDIA Container Toolkit components installed."
