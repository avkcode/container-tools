#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

# Python version information
PYTHON_VERSION="${PYTHON_VERSION:-3.9.18}"
PYTHON_MINOR="$(echo "$PYTHON_VERSION" | cut -d. -f1-2)"
PYTHON_SHA="${PYTHON_SHA:-01597db0132c1cf7b331eff68ae09b5a235a3c3caa9c944c29cac7d1c4c4c00a}"
PYTHON_URL="${PYTHON_URL:-https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz}"

install_python() {
    echo "==> Installing build dependencies"
    apt-get update
    # Add curl and xz-utils for download/extract; ca-certificates for TLS
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        zlib1g-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libbz2-dev \
        libsqlite3-dev \
        liblzma-dev \
        tk-dev \
        ca-certificates \
        curl \
        xz-utils

    echo "==> Downloading Python ${PYTHON_VERSION}"
    tmp_tar="/tmp/Python-${PYTHON_VERSION}.tar.xz"
    curl --fail --location --silent --show-error --output "${tmp_tar}" "${PYTHON_URL}"

    echo "==> Verifying checksum"
    if ! echo "${PYTHON_SHA}  ${tmp_tar}" | sha256sum --check --status; then
        echo "ERROR: Python checksum verification failed" >&2
        exit 1
    fi

    echo "==> Preparing source tree"
    mkdir -p /usr/src/python
    tar -xJf "${tmp_tar}" -C /usr/src/python --strip-components=1

    echo "==> Refreshing config.sub and config.guess"
    curl -fsSL -o /usr/src/python/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
    curl -fsSL -o /usr/src/python/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
    chmod +x /usr/src/python/config.sub /usr/src/python/config.guess

    echo "==> Building Python ${PYTHON_VERSION}"
    cd /usr/src/python
    ./configure \
        --prefix=/usr \
        --enable-optimizations \
        --enable-shared \
        --with-system-ffi \
        --with-ensurepip=install \
        LDFLAGS="-Wl,-rpath=/usr/lib"
    make -j"$(nproc)" || make
    make install

    echo "==> Linking convenience binaries"
    ln -sf "/usr/bin/python${PYTHON_MINOR}" "/usr/bin/python3" || true
    ln -sf "/usr/bin/python${PYTHON_MINOR}" "/usr/bin/python" || true
    ln -sf "/usr/bin/pip${PYTHON_MINOR}" "/usr/bin/pip3" || true
    ln -sf "/usr/bin/pip${PYTHON_MINOR}" "/usr/bin/pip" || true

    echo "==> Running ldconfig"
    ldconfig

    echo "==> Cleaning up build dependencies and caches"
    DEBIAN_FRONTEND=noninteractive apt-get purge -y \
        build-essential \
        zlib1g-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libbz2-dev \
        libsqlite3-dev \
        liblzma-dev \
        tk-dev
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
    apt-get clean
    rm -rf /var/lib/apt/lists/* /usr/src/python "${tmp_tar}"

    echo "==> Verifying installation"
    if /usr/bin/python3 --version >/dev/null 2>&1; then
        echo "Python ${PYTHON_VERSION} installed successfully"
    else
        echo "ERROR: Python installation failed - /usr/bin/python3 not working" >&2
        exit 1
    fi
}

install_python
