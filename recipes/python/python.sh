#!/usr/bin/env bash

# Python version information
PYTHON_VERSION='3.9.18'
PYTHON_SHA='01597db0132c1cf7b331eff68ae09b5a235a3c3caa9c944c29cac7d1c4c4c00a'
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"

python() {
    # Fix package system first
    echo "➤ Preparing package system..."
    run apt-get update -o Acquire::Retries=3
    run apt-get install -f -y
    run dpkg --configure -a

    # Install build dependencies including autoconf
    echo "➤ Installing build dependencies..."
    local deps=(
        build-essential
        zlib1g-dev
        libssl-dev
        libreadline-dev
        libffi-dev
        wget
        ca-certificates
        xz-utils
        libbz2-dev
        libsqlite3-dev
        liblzma-dev
        tk-dev
        autoconf
        automake
        libtool
    )
    
    run apt-get install -y --no-install-recommends "${deps[@]}" || {
        echo "⚠️ Standard install failed, trying with downgrade allowances..."
        run apt-get install -y \
            --allow-downgrades \
            --allow-change-held-packages \
            "${deps[@]}"
    }

    # Download and verify Python
    echo "➤ Downloading Python ${PYTHON_VERSION}..."
    if [[ ! -f "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" ]]; then
        download "${PYTHON_URL}" "Python-${PYTHON_VERSION}.tar.xz" "${DOWNLOAD}" ||
            die "Failed to download Python"
    fi
    
    check_sum "${PYTHON_SHA}" "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" ||
        die "Checksum verification failed"

    # Extract source
    echo "➤ Extracting source code..."
    run mkdir -p "${DOWNLOAD}/python-src"
    run tar -xJf "${DOWNLOAD}/Python-${PYTHON_VERSION}.tar.xz" \
        -C "${DOWNLOAD}/python-src" ||
        die "Failed to extract Python source"

    # Fix config.sub before configure
    echo "➤ Updating config.sub and config.guess..."
    run cd "${DOWNLOAD}/python-src/Python-${PYTHON_VERSION}"
    run wget -O config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
    run wget -O config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
    run chmod +x config.sub config.guess

    # Configure Python with host/build specification
    echo "➤ Configuring Python..."
    ./configure \
        --prefix=/opt/python \
        --build=$(./config.guess) \
        --host=$(./config.guess) \
        --enable-optimizations \
        --with-ensurepip=install \
        --with-system-ffi \
        --enable-loadable-sqlite-extensions \
        || die "Configure failed"

    # Build with reduced parallelism
    echo "➤ Building Python (this may take a while)..."
    run make -j$(($(nproc)/2)) || {
        echo "⚠️ Parallel build failed, trying single thread..."
        run make || die "Build failed"
    }

    # Install Python
    echo "➤ Installing Python..."
    run mkdir -p "${target}/opt/python"
    run make altinstall DESTDIR="${target}" ||
        die "Installation failed"

    # Create symlinks
    echo "➤ Creating symlinks..."
    run mkdir -p "${target}/usr/bin"
    run ln -sf "/opt/python/bin/python${PYTHON_MINOR_VERSION}" \
        "${target}/usr/bin/python${PYTHON_MINOR_VERSION}"
    run ln -sf "/opt/python/bin/pip${PYTHON_MINOR_VERSION}" \
        "${target}/usr/bin/pip${PYTHON_MINOR_VERSION}"
    run ln -sf "python${PYTHON_MINOR_VERSION}" "${target}/usr/bin/python3"
    run ln -sf "python${PYTHON_MINOR_VERSION}" "${target}/usr/bin/python"
    run ln -sf "pip${PYTHON_MINOR_VERSION}" "${target}/usr/bin/pip3"
    run ln -sf "pip${PYTHON_MINOR_VERSION}" "${target}/usr/bin/pip"

    # Set up library paths
    echo "/opt/python/lib" > "${target}/etc/ld.so.conf.d/python.conf"
    chroot "${target}" ldconfig

    # Clean up
    echo "➤ Cleaning up..."
    run apt-get clean
    run rm -rf /var/lib/apt/lists/*
    run rm -rf "${DOWNLOAD}/python-src"

    echo "✅ Python ${PYTHON_VERSION} installed successfully"
}
