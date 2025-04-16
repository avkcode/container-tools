#!/usr/bin/env bash

# Python version information
PYTHON_VERSION='3.9.18'
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f1-2)
PYTHON_SHA='01597db0132c1cf7b331eff68ae09b5a235a3c3caa9c944c29cac7d1c4c4c00a'
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"

python() {
    header "Installing build dependencies"
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
    run apt-get update
    run apt-get install -y --no-install-recommends "${build_deps[@]}"

    header "Downloading Python ${PYTHON_VERSION}"
    if [[ ! -f "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" ]]; then
        download "${PYTHON_URL}" "Python-${PYTHON_VERSION}.tar.xz" "${DOWNLOAD}" ||
            die "Failed to download Python"
    fi
    check_sum "${PYTHON_SHA}" "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" ||
        die "Checksum verification failed"

    header "Building Python ${PYTHON_VERSION}"
    run mkdir -p "${DOWNLOAD}/python-build"
    run tar -xJf "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" -C "${DOWNLOAD}/python-build" --strip-components=1
    
    pushd "${DOWNLOAD}/python-build" >/dev/null
    
    # Fix for modern systems
    run curl -o config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
    run curl -o config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
    run chmod +x config.sub config.guess

    # Configure with optimizations
    ./configure \
        --prefix=/usr \
        --enable-optimizations \
        --enable-shared \
        --with-system-ffi \
        --with-ensurepip=install \
        LDFLAGS="-Wl,-rpath=/usr/lib"

    # Build with limited parallelism
    run make -j$(($(nproc)/2)) || run make
    
    # Install into target
    run make install DESTDIR="$target"
    popd >/dev/null

    header "Creating symlinks"
    run ln -sf "/usr/bin/python${PYTHON_MINOR}" "$target/usr/bin/python3"
    run ln -sf "/usr/bin/python${PYTHON_MINOR}" "$target/usr/bin/python"
    run ln -sf "/usr/bin/pip${PYTHON_MINOR}" "$target/usr/bin/pip3"
    run ln -sf "/usr/bin/pip${PYTHON_MINOR}" "$target/usr/bin/pip"

    header "Cleaning up"
    run apt-get purge -y "${build_deps[@]}"
    run apt-get autoremove -y
    run apt-get clean
    run rm -rf "${DOWNLOAD}/python-build" /var/lib/apt/lists/*
 
    header "Verifying installation"
    if [ -f "$target/usr/bin/python${PYTHON_MINOR}" ]; then
        info "Python found at /usr/bin/python${PYTHON_MINOR}"
    else
        die "Python installation failed - binary not found"
    fi

    info "Python ${PYTHON_VERSION} installed successfully"
}
