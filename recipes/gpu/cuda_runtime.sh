#!/usr/bin/env bash
# Minimal CUDA runtime integration for NVIDIA GPUs via NVIDIA Container Toolkit.
# - Keeps image minimal; relies on host drivers and toolkit to mount libraries
# - Idempotent: safe to run multiple times
# - Optional: set CUDA_RUNTIME_INSTALL=1 to attempt minimal CUDA runtime libs

set -euo pipefail

log() { echo "[cuda-runtime] $*"; }

# Provide sensible defaults for NVIDIA runtime via profile.d
profile_file="/etc/profile.d/nvidia-container-toolkit.sh"
mkdir -p "$(dirname "$profile_file")"
cat > "$profile_file" <<'EOF'
# NVIDIA Container Toolkit integration hints
# These defaults can be overridden at runtime with -e VAR=value
export NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES:-all}"
export NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}"
# Uncomment to require a minimum CUDA version:
# export NVIDIA_REQUIRE_CUDA="${NVIDIA_REQUIRE_CUDA:-cuda>=12.0 brand=tesla,driver>=525}"
EOF
chmod 0644 "$profile_file"

# Add common CUDA library search paths in case libs are mounted here by the toolkit
ld_conf="/etc/ld.so.conf.d/cuda.conf"
if [ ! -f "$ld_conf" ]; then
  cat > "$ld_conf" <<'EOF'
/usr/local/cuda/lib64
/usr/local/cuda/lib
/usr/local/cuda/compat
/usr/lib/x86_64-linux-gnu
/usr/lib/aarch64-linux-gnu
EOF
fi

# Optional minimal CUDA compatibility/runtime libraries (disabled by default)
# Note: Actual CUDA libs are typically injected by the NVIDIA Container Toolkit from the host.
if [ "${CUDA_RUNTIME_INSTALL:-}" = "1" ]; then
  log "Attempting optional installation of CUDA compatibility/runtime libraries..."
  export DEBIAN_FRONTEND=noninteractive
  set +e
  arch="$(dpkg --print-architecture 2>/dev/null || echo x86_64)"
  # Install NVIDIA CUDA repository keyring (arch-independent)
  if ! dpkg -s cuda-keyring >/dev/null 2>&1; then
    tmpdeb="/tmp/cuda-keyring_1.1-1_all.deb"
    curl -fsSL -o "$tmpdeb" "https://developer.download.nvidia.com/compute/cuda/repos/debian11/${arch}/cuda-keyring_1.1-1_all.deb" || \
    curl -fsSL -o "$tmpdeb" "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.1-1_all.deb"
    dpkg -i "$tmpdeb" || true
    rm -f "$tmpdeb"
  fi
  apt-get update || true
  # Try likely minimal runtime packages; ignore failures to keep build portable
  apt-get install -y --no-install-recommends cuda-compat-12-5 || true
  apt-get install -y --no-install-recommends libcudart12 || true
  apt-get install -y --no-install-recommends cuda-cudart-12-5 || true
  apt-get clean || true
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* || true
  set -e
else
  log "Skipping CUDA library installation (set CUDA_RUNTIME_INSTALL=1 to attempt minimal install)."
fi

# Informational MOTD
mkdir -p /etc/motd.d
cat > /etc/motd.d/99-cuda-runtime <<'EOF'
This image is prepared for NVIDIA GPUs using the NVIDIA Container Toolkit.
Run containers with GPU access enabled, for example:

  docker run --rm -it --gpus all <image> nvidia-smi

Requirements:
- NVIDIA drivers installed on the host
- NVIDIA Container Toolkit configured on the host:
  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
EOF
chmod 0644 /etc/motd.d/99-cuda-runtime

log "CUDA runtime base setup complete."
