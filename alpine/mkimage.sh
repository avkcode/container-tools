#!/usr/bin/env bash

# Enable tracing if TRACE environment variable is set
if [ -n "$TRACE" ]; then
  export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
  set -o xtrace
fi

# Exit on error, nounset, and pipefail
set -o errexit
set -o pipefail
set -o nounset

# Function to display usage information
usage() {
  cat <<EOF
Usage: ${0} [options]

Description:
  This script automates the process of building a minimal Alpine Linux image.
  It creates a rootfs, installs necessary packages, and archives the resulting image.

Options:
  --alpine-version=<version>     Specify the Alpine version (e.g., v3.19, latest-stable).
  --output-dir=<dir>             Specify the output directory for the image.
  --packages=<packages>          Comma-separated list of packages to install.
  --mirror=<mirror>              Specify the Alpine mirror to use.
  --help                         Display this help message.

Example:
  ${0} --alpine-version=v3.19 --packages=alpine-base,nodejs,npm --output-dir=./dist

Notes:
  - Ensure that you have root privileges for certain operations.
EOF
  exit 1
}

# Parse command-line arguments
OPTIND=1
while getopts ":-:" optchar; do
  [[ "${optchar}" == "-" ]] || continue
  case "${OPTARG}" in
  alpine-version=*)
    alpine_version=${OPTARG#*=}
    if [[ -z "$alpine_version" ]]; then
      echo "Missing value for --alpine-version"
      exit 1
    fi
    ;;
  output-dir=*)
    output_dir=${OPTARG#*=}
    if [[ -z "$output_dir" ]]; then
      echo "Missing value for --output-dir"
      exit 1
    fi
    ;;
  packages=*)
    packages=${OPTARG#*=}
    if [[ -z "$packages" ]]; then
      echo "Missing value for --packages"
      exit 1
    fi
    ;;
  mirror=*)
    mirror=${OPTARG#*=}
    if [[ -z "$mirror" ]]; then
      echo "Missing value for --mirror"
      exit 1
    fi
    ;;
  help*)
    usage
    ;;
  *)
    echo "Unknown argument: '$OPTARG'. Did you mean one of these?"
    echo "  --alpine-version=<value>"
    echo "  --output-dir=<value>"
    echo "  --packages=<value>"
    echo "  --mirror=<value>"
    echo "Run ${0} --help for more information."
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

############################## FUNCTIONS ##############################

# Function to run commands with error handling
run() {
  echo >&2 "$(timestamp) RUN $* "
  "${@}"
  e=$?

  if ((e != 0)); then
    echo >&2 "Error code: $e, program was interrupted"
    exit
  fi
}

# Function to print headers
header() {
  echo
  msg="${1:-}"
  echo
  printf ["$msg"] >/dev/stderr
  echo
  printf ':%.0s' $(seq 1 80)
  echo
}

# Function to generate a timestamp
timestamp() {
  date +"[%Y-%m-%d %T] -"
}

# Function to exit with an error message
die() {
  echo "ERROR $*" >&2
  exit 1
}

# Function to print warnings
warn() {
  echo >&2 "$(timestamp) WARN $*"
}

# Function to print informational messages
info() {
  echo >&2 "$(timestamp) INFO $*"
}

############################## VARS & CHECKS ##############################

# Check if the OS is Linux
if [[ "$(uname -s)" != "Linux" ]]; then
  die "GNU/Linux is the only supported OS"
fi

# Check for Vagrant environment
if [[ -d /vagrant ]]; then
  info "Vagrant environment detected"
fi

# Check if the script is run as root
if [[ "$EUID" != "0" ]]; then
  die "${BASH_SOURCE[0]} requires root privileges"
fi

# Set default values if not provided
alpine_version=${alpine_version:-"v3.19"}
output_dir=${output_dir:-"./dist"}
packages=${packages:-"alpine-base"}
mirror=${mirror:-"http://dl-cdn.alpinelinux.org/alpine"}

# Set up temporary directories
target="$(mktemp --directory)"
tmpdir="$(mktemp --directory --tmpdir tmp-XXXXX)"
rootfs_dir="$target/rootfs"
mkdir -p "$rootfs_dir"

# Ensure cleanup on exit/failure
cleanup() {
  [[ -n "${target:-}" && -d "$target" ]] && rm -rf "$target" || true
  [[ -n "${tmpdir:-}" && -d "$tmpdir" ]] && rm -rf "$tmpdir" || true
}
trap 'cleanup' EXIT INT TERM

# Create output directory
image_name="alpine${alpine_version/v/}"
dist_dir="${output_dir}/${image_name}"
mkdir -p "$dist_dir"

############################## SCRIPT MAIN ##############################

main() {
  header "Building Alpine Linux rootfs"
  info "Alpine version: $alpine_version"
  info "Output directory: $dist_dir"
  info "Packages to install: $packages"
  info "Using mirror: $mirror"

  # Create necessary directories
  mkdir -p "$rootfs_dir/etc/apk"
  
  # Configure repositories
  echo "$mirror/$alpine_version/main" > "$rootfs_dir/etc/apk/repositories"
  echo "$mirror/$alpine_version/community" >> "$rootfs_dir/etc/apk/repositories"
  
  # Install Alpine Linux
  info "Installing base system"
  run apk --root "$rootfs_dir" add --no-cache $packages
  
  # Configure the system
  info "Configuring system"
  
  # Set up /etc/os-release
  cat > "$rootfs_dir/etc/os-release" <<EOF
NAME="Alpine Linux"
ID=alpine
VERSION_ID=${alpine_version/v/}
PRETTY_NAME="Alpine Linux ${alpine_version/v/}"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://bugs.alpinelinux.org/"
EOF
  
  # Clean up
  info "Cleaning up"
  run rm -rf "$rootfs_dir/var/cache/apk"/*
  
  # Create tarball
  info "Creating tarball"
  GZIP="--no-name" run tar --numeric-owner -czf "$dist_dir/$image_name.tar" --directory "$rootfs_dir" . --transform='s,^./,,' --mtime='1970-01-01'
  sha256sum "$dist_dir/$image_name.tar" > "$dist_dir/$image_name.sha256"
  
  # Create metadata file
  info "Creating metadata"
  cat > "$dist_dir/metadata.json" <<EOF
{
  "alpine_version": "${alpine_version}",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "packages": "${packages}"
}
EOF
  
  # Clean up temporary directories
  info "Cleaning up temporary directories"
  run rm -rf "$target"
  run rm -rf "$tmpdir"
  
  header "Image was built successfully"
  echo
  echo "Artifact location: $dist_dir/$image_name.tar"
  echo
  echo "Artifact size: $(du -h "$dist_dir/$image_name.tar" | cut -f1)"
  echo
  echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  echo "Image was built successfully"
  echo "Artifact location: $dist_dir/$image_name.tar"
  echo ""
  echo "To load and run this Docker image, follow these steps:"
  echo ""
  echo "Load the Docker image from the .tar file:"
  echo "   docker import $dist_dir/$image_name.tar $image_name"
  echo ""
  echo "Verify the image was loaded successfully:"
  echo "   docker images"
  echo ""
  echo "Run the Docker container:"
  echo "   docker run -it $image_name /bin/sh"
  echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
}

main "${@}" 2>&1 | tee "$dist_dir/build.log"
