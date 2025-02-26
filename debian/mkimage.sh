#!/usr/bin/env bash

# Enable tracing if TRACE environment variable is set
if [ -n "$TRACE" ]; then
  export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
  set -o xtrace
fi

# Exit on error and pipefail
set -o errexit
set -o pipefail

# Set non-interactive frontend for Debian packages
export DEBIAN_FRONTEND=noninteractive

# Get the directory of the script
scriptdir=$(dirname "${BASH_SOURCE[0]}")

# Function to display usage information
usage() {
  cat <<EOF
Usage: ${0} [options]

Description:
  This script automates the process of building a minimal Debian-based image.
  It uses debootstrap to create a chroot environment, installs necessary packages,
  runs custom scripts, and archives the resulting image.

Options:
  --name=<name>                  Specify the name of the output image file.
  --release=<release>            Specify the Debian release (e.g., bullseye, buster).
  --keyring=<keyring>            Specify the keyring package for debootstrap.
  --variant=<variant>            Specify the debootstrap variant (e.g., minbase).
  --repo_config=<repo_config>    Specify the repository configuration file.
  --debootstrap_packages=<pkgs>  Comma-separated list of packages for debootstrap.
  --packages=<pkgs>              Comma-separated list of additional packages to install.
  --recipes=<recipes>            Comma-separated list of installer scripts to run.
  --scripts=<scripts>            Comma-separated list of test scripts to execute.
  --help                         Display this help message.

Example:
  ${0} --name=my-image --release=bullseye --packages=curl,vim --scripts=test.sh

Notes:
  - Ensure that debootstrap, unzip, and trivy are installed on your system.
  - The script requires root privileges for certain operations.
EOF
  exit 1
}

# Parse command-line arguments
OPTIND=1
while getopts ":-:" optchar; do
  [[ "${optchar}" == "-" ]] || continue
  case "${OPTARG}" in
  name=*)
    name=${OPTARG#*=}
    if [[ -z "$name" ]]; then
      die "Missing value for --name"
    fi
    ;;
  release=*)
    release=${OPTARG#*=}
    if [[ -z "$release" ]]; then
      die "Missing value for --release"
    fi
    ;;
  keyring=*)
    keyring=${OPTARG#*=}
    if [[ -z "$keyring" ]]; then
      die "Missing value for --keyring"
    fi
    ;;
  variant=*)
    variant=${OPTARG#*=}
    ;;
  repo_config=*)
    repo_config=${OPTARG#*=}
    ;;
  debootstrap_packages=*)
    debootstrap_packages=${OPTARG#*=}
    ;;
  packages=*)
    packages=${OPTARG#*=}
    packages=("${packages//,/ }")
    ;;
  recipes=*)
    recipes=${OPTARG#*=}
    recipes=("${recipes//,/ }")
    ;;
  scripts=*)
    scripts=${OPTARG#*=}
    scripts=("${scripts//,/ }")
    ;;
  help*)
    usage
    ;;
  *)
    echo "Unknown argument: '$OPTARG'. Did you mean one of these?"
    echo "  --name=<value>"
    echo "  --release=<value>"
    echo "  --keyring=<value>"
    echo "Run ${0} --help for more information."
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

############################## FUNCTIONS ##############################

# Check if debootstrap is installed
if ! command -v debootstrap >/dev/null 2>&1; then
    echo "Error: debootstrap is not installed."
    echo "To install debootstrap, run:"
    echo "  sudo apt-get update && sudo apt-get install debootstrap"
    exit 1
fi

# Check if unzip is installed
if ! command -v unzip >/dev/null 2>&1; then
    echo "Error: unzip is not installed."
    echo "To install unzip, run:"
    echo "  sudo apt-get update && sudo apt-get install unzip"
    exit 1
fi

# Check if trivy is installed
if ! command -v trivy >/dev/null 2>&1; then
    echo "Error: trivy is not installed."
    echo "Trivy is a security scanner used to detect vulnerabilities, misconfigurations, and secrets."
    echo "To install trivy, follow these steps:"
    echo ""
    echo "For Linux/macOS:"
    echo "   Download the latest release from https://github.com/aquasecurity/trivy/releases"
    echo "   Example for Linux:"
    echo "   curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
    echo ""
    exit 1
fi

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

# Function to source all files in a directory
source-files-in() {
  local dir="$1"

  if [[ -d "$dir" && -r "$dir" && -x "$dir" ]]; then
    for file in "$dir"/*; do
      [[ -f "$file" && -r "$file" ]] && run source "$file"
    done
  fi
}

# Function to print array elements
print-array() {
  printf '%s\n' "${@}"
}

# Function to print logs
printlog() {
  printf '\n'
  printf '%s\n' "${*}"
  printf '\n'
}

# Function to check if required commands are installed
check-commands() {
  local commands=("${@}")

  for cmd in $(print-array "${commands[@]}"); do
    echo "Checking command $cmd"
    if ! command -v "$cmd" &>/dev/null; then
      die "$cmd not found"
    fi
  done
}

# Function to start a timer
timer-on() {
  start=$(date +%s)
}

# Function to stop a timer and display elapsed time
timer-off() {
  end=$(date +%s)
  elapsed=$((end - start))
  echo "Time elapsed: $elapsed"
  echo
}

# Function to get the real path of a file
frealpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# Function to retry a command
retry() {
  local tries=$1
  shift

  local i=0
  while [ "$i" -lt "$tries" ]; do
    "$@" && return 0
    sleep $((2**((i++))))
  done

  return 1
}

# Function to check file checksum
check_sum() {
  local sum=$1
  local file=$2
  local sha=$3

  info "File: $file"
  info "Checking: $sum"

  if [[ $sha == "sha512sum" ]]; then
    sha=sha512sum
  else
    sha=sha256sum
  fi

  ${sha} --check - <<EOF
${sum} ${file}
EOF
}

# Function to download a file
download() {
  local url="$1"
  local output_file="$2"
  local output_dir="$3"
  local tmpfile

  tmpfile=$(mktemp "$output_dir/.download_XXXX")
  trap "rm --force -- ${tmpfile}" EXIT

  if run curl --silent --location --retry 3 --retry-delay 1 --fail --show-error --output "$tmpfile" "$url"; then
    run mv "$tmpfile" $output_dir/"$output_file"
  else
    run rm --force "$tmpfile"
    return 1
  fi
}

############################## VARS & CHECKS ##############################

# Check if the OS is Linux
if [[ "$(uname -s)" != "Linux" ]]; then
  die "GNU/Linux is the only supported OS"
fi

# Check if the script is run as root
if [[ "$EUID" != "0" ]]; then
  die "${BASH_SOURCE[0]} requires root privileges"
fi

# Check if SELinux is enabled and permissive/disabled
if command -v getenforce; then
  if [[ ! "$(getenforce | grep --extended-regexp "Permissive|Disabled")" ]]; then
    die "Disable SELinux or create container policy"
  fi
fi

# Use podman if available, otherwise fall back to docker
if ! command -v podman; then
  warn "Podman will be used for building images"
  podman=docker
else
  podman=podman
fi

# Set up temporary directories
target="$(mktemp --directory)"
tmpdir="$(mktemp --directory --tmpdir tmp-XXXXX)"
debootstrap_dir="$tmpdir"
logfile="$(date +%F_%H_%M_%S)"
dist="$scriptdir"/dist/$name && mkdir --parents "$dist"
DOWNLOAD='download'
mkdir --parents "$DOWNLOAD"

# Define repository URLs
repo_url="http://deb.debian.org/debian"
sec_repo_url="http://security.debian.org/"

############################## SCRIPT MAIN ##############################

header "Script args"
printf '%s\n' "${BASH_ARGV[@]}" "${BASH_SOURCE[0]}" | tac | tr '\n' ' ' && echo

header "Environment variables"
run printenv

main() {
  timer-on

  # Fix GPG directory and import keys
  header "Setting up GPG directory"
  run rm -rf /root/.gnupg
  run mkdir -p /root/.gnupg
  run chmod 700 /root/.gnupg

  header "Importing GPG keys"
  run gpg --no-default-keyring --keyring /root/.gnupg/trustedkeys.gpg --import "$scriptdir"/keys/buster.gpg
  run gpg --no-default-keyring --keyring /root/.gnupg/trustedkeys.gpg --import "$scriptdir"/keys/unstable.gpg

  header "Preparing debootstrap scripts"
  run cp --archive /usr/share/debootstrap/* "$debootstrap_dir"
  run cp --archive "$scriptdir"/debootstrap/* "$debootstrap_dir/scripts"

  header "Using debootstrap to create rootfs"
  info "Building in chroot: $target"
  DEBOOTSTRAP_DIR="$debootstrap_dir" run debootstrap --no-check-gpg --keyring "$keyring" --variant "$variant" "${debootstrap_packages[@]}" --foreign "$release" "$target"
  LANG=C run chroot "$target" bash debootstrap/debootstrap --verbose --second-stage

  header "Configuring apt repos"
  echo "deb $repo_url $release-updates main" >> "$target"/etc/apt/sources.list
  echo "deb $sec_repo_url $release-security main" >> "$target"/etc/apt/sources.list
  run chroot "$target" apt-get update && apt-get install --yes --option Dpkg::Options::="--force-confdef"

  if [[ -v packages[@] ]]; then
    header "Installing packages"
    info "The following packages will be installed in chroot:"
    print-array ${packages[@]}
    echo
    run chroot "$target" apt-get update && retry 3 chroot "$target" apt-get install --yes --no-install-recommends "${packages[@]}"
    info "Installed packages:"
    chroot "$target" dpkg-query --show --showformat='${Package} ${Installed-Size}\n'
  fi

  if [[ -v recipes[@] ]]; then
    header "Running installer scripts"
    while read -r line; do
      info "Running ${line}"
      run source "${line}" && `basename ${line} .sh`
    done < <(print-array ${recipes[@]})
  fi

  header "Apply Docker-specific apt settings"
  run chroot "$target" apt-get --option Acquire::Check-Valid-Until=false update
  run chroot "$target" apt-get --yes --quiet upgrade
  echo '#!/bin/sh' > "$target"/usr/sbin/policy-rc.d
  echo 'exit 101' >> "$target"/usr/sbin/policy-rc.d
  run chmod +x "$target"/usr/sbin/policy-rc.d
  run dpkg-divert --local --rename --add "$target"/sbin/initctl
  run cp --archive "$target"/usr/sbin/policy-rc.d "$target"/sbin/initctl
  run sed --in-place 's/^exit.*/exit 0/' "$target"/sbin/initctl
  echo 'force-unsafe-io' > "$target"/etc/dpkg/dpkg.cfg.d/docker-apt-speedup
  echo 'DPkg::Post-Invoke { "rm --force /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > "$target"/etc/apt/apt.conf.d/docker-clean
  echo 'APT::Update::Post-Invoke { "rm --force /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> "$target"/etc/apt/apt.conf.d/docker-clean
  echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> "$target"/etc/apt/apt.conf.d/docker-clean
  echo 'Acquire::Languages "none";' > "$target"/etc/apt/apt.conf.d/docker-no-languages
  echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > "$target"/etc/apt/apt.conf.d/docker-gzip-indexes
  echo 'Apt::AutoRemove::SuggestsImportant "false";' > "$target"/etc/apt/apt.conf.d/docker-autoremove-suggests

  header "Remove optional files to reduce the size of the directory"
  run chroot "$target" apt-get clean
  run chroot "$target" apt-get --yes autoremove
  run rm --recursive --force "$target"/dev "$target"/proc
  run mkdir --parents "$target"/dev "$target"/proc
  run rm --recursive --force "$target"/usr/bin/pinky
  run rm --recursive --force "$target"/etc/apt/apt.conf.d/01autoremove-kernels
  run rm --recursive --force "$target"/etc/machine-id
  run rm --recursive --force "$target"/etc/boot
  run rm --recursive --force "$target"/etc/hostname
  run rm --recursive --force "$target"/tmp/* "$target"/var/tmp/*
  run rm --recursive --force "$target"/etc/systemd/* "$target"/lib/systemd/*
  run rm --recursive --force "$target"/var/lib/apt/lists/*
  run rm --recursive --force "$target"/usr/share/info/*
  run rm --recursive --force "$target"/usr/lib/x86_64-linux-gnu/gconv/IBM* "$target"/usr/lib/x86_64-linux-gnu/gconv/EBC*
  run rm --recursive --force "$target"/usr/share/groff
  run rm --recursive --force "$target"/usr/share/lintian
  run rm --recursive --force "$target"/usr/share/linda
  run rm --recursive --force "$target"/var/lib/apt/lists/*
  run rm --recursive --force "$target"/usr/share/doc/*
  run rm --recursive --force "$target"/usr/share/pixmaps/*
  run rm --recursive --force "$target"/usr/share/locale/*
  run find "$target"/var/cache -type f -exec rm --recursive --force {} \;
  run find "$target"/var/log -type f -exec truncate --size 0 {} \;
  run rm --recursive --force "$target"/etc/ld.so.cache && run chroot "$target" ldconfig

  if [[ -v scripts[@] ]]; then
    header "Running tests"
    source "${scripts}"
  fi

  header "Archiving image"
  GZIP="--no-name" run tar --numeric-owner -czf "$dist"/"$name".tar --directory "$target" . --transform='s,^./,,' --mtime='1970-01-01'
  md5sum "$dist"/"$name".tar > "$dist"/"$name".SUM

  header "Remove temporary directories"
  run rm --recursive --force "$target"
  run rm --recursive --force "$debootstrap_dir"

  header "Image was built successfully"
  echo
  echo "Artifact location: "$dist"/"$name".tar"
  echo
  echo "Artifact size: `du --summarize --human-readable "$dist"/"$name".tar | cut --fields 1`"
  echo
  echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  echo "Image was built successfully!"
  echo "Artifact location: "$dist"/"$name".tar"
  echo ""
  echo "To load and run this Docker image, follow these steps:"
  echo ""
  echo "Load the Docker image from the .tar file:"
  echo "   cat "$dist"/"$name".tar | docker import - "$dist"/"$name""
  echo ""
  echo "Verify the image was loaded successfully:"
  echo "   docker images"
  echo ""
  echo "Run the Docker container:"
  echo "   docker run -it <IMAGE_NAME>"
  echo "   Replace <IMAGE_NAME> with the name of the image loaded in the first step."
  echo ""
  echo "Example:"
  echo "   docker run -it "$dist"/"$name" /bin/bash"
  echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

  timer-off
}

main "${@}" 2>&1 | tee "$dist"/"$logfile".log
