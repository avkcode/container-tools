#!/usr/bin/env bash

# Python version information
PYTHON_VERSION="${PYTHON_VERSION:-3.9.18}"
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f1-2)
PYTHON_SHA="${PYTHON_SHA:-01597db0132c1cf7b331eff68ae09b5a235a3c3caa9c944c29cac7d1c4c4c00a}"
PYTHON_URL="${PYTHON_URL:-https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz}"

python() {
    header "Installing build dependencies inside target"
    local build_deps=(
        build-essential
        zlib1g-dev
        libssl-dev
        libreadline-dev
        libffi-dev
        libbz2-dev
        libsqlite3-dev
        liblzma-dev
        tk-dev
    )
    run chroot "$target" apt-get update
    run chroot "$target" apt-get install -y --no-install-recommends "${build_deps[@]}"

    header "Downloading Python ${PYTHON_VERSION}"
    if [[ ! -f "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" ]]; then
        download "${PYTHON_URL}" "Python-${PYTHON_VERSION}.tar.xz" "${DOWNLOAD}" ||
            die "Failed to download Python"
    fi
    check_sum "${PYTHON_SHA}" "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" ||
        die "Checksum verification failed"

    header "Preparing source tree in target"
    run mkdir -p "$target/usr/src/python"
    run tar -xJf "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" -C "$target/usr/src/python" --strip-components=1

    # Refresh config.sub and config.guess for broader arch support
    run curl -fsSL -o "$target/usr/src/python/config.sub" 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
    run curl -fsSL -o "$target/usr/src/python/config.guess" 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
    run chmod +x "$target/usr/src/python/config.sub" "$target/usr/src/python/config.guess"

    header "Building Python ${PYTHON_VERSION} inside chroot"
    run chroot "$target" /bin/bash -o pipefail -ec '
        set -euo pipefail
        cd /usr/src/python
        ./configure \
            --prefix=/usr \
            --enable-optimizations \
            --enable-shared \
            --with-system-ffi \
            --with-ensurepip=install \
            LDFLAGS="-Wl,-rpath=/usr/lib"
        make -j"$(($(nproc)/2))" || make
        make install
    '

    header "Creating symlinks"
    run ln -sf "/usr/bin/python${PYTHON_MINOR}" "$target/usr/bin/python3"
    run ln -sf "/usr/bin/python${PYTHON_MINOR}" "$target/usr/bin/python"
    run ln -sf "/usr/bin/pip${PYTHON_MINOR}" "$target/usr/bin/pip3"
    run ln -sf "/usr/bin/pip${PYTHON_MINOR}" "$target/usr/bin/pip"

    header "Cleaning up build dependencies and caches in target"
    run chroot "$target" apt-get purge -y "${build_deps[@]}"
    run chroot "$target" apt-get autoremove -y
    run chroot "$target" apt-get clean
    run rm -rf "$target/var/lib/apt/lists/"*
    run rm -rf "$target/usr/src/python"
 
    header "Verifying installation"
    if chroot "$target" /usr/bin/python3 --version >/dev/null 2>&1; then
        info "Python found via chroot at /usr/bin/python3"
    else
        die "Python installation failed - /usr/bin/python3 not working"
    fi

    info "Python ${PYTHON_VERSION} installed successfully"
}
