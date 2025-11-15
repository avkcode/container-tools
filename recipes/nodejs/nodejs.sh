#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

# Node.js Current (23.x) version
NODE_VERSION="${NODE_VERSION:-23.11.0}"
NODE_SHA="${NODE_SHA:-fa9ae28d8796a6cfb7057397e1eea30ca1c61002b42b8897f354563a254e7cf5}"
NODE_URL="${NODE_URL:-https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz}"

install_nodejs() {
    echo "==> Installing prerequisites"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        xz-utils

    echo "==> Downloading Node.js ${NODE_VERSION}"
    tmp_tar="/tmp/node-v${NODE_VERSION}-linux-x64.tar.xz"
    curl --fail --location --silent --show-error --output "${tmp_tar}" "${NODE_URL}"

    echo "==> Verifying checksum"
    if ! echo "${NODE_SHA}  ${tmp_tar}" | sha256sum --check --status; then
        echo "ERROR: Node.js checksum verification failed" >&2
        exit 1
    fi

    echo "==> Installing Node.js to /opt/nodejs"
    mkdir -p /opt/nodejs
    tar -xJf "${tmp_tar}" --strip-components=1 --directory /opt/nodejs

    echo "==> Creating symlinks"
    mkdir -p /usr/local/bin /usr/bin
    ln -sf /opt/nodejs/bin/node /usr/local/bin/node
    ln -sf /opt/nodejs/bin/npm /usr/local/bin/npm
    ln -sf /opt/nodejs/bin/npx /usr/local/bin/npx
    ln -sf /opt/nodejs/bin/node /usr/bin/node
    ln -sf /opt/nodejs/bin/npm /usr/bin/npm
    ln -sf /opt/nodejs/bin/npx /usr/bin/npx

    echo "==> Writing /etc/profile.d/nodejs.sh"
    mkdir -p /etc/profile.d
    cat > /etc/profile.d/nodejs.sh <<'EOF'
export NODE_HOME=/opt/nodejs
export PATH="$NODE_HOME/bin:$PATH"
EOF
    chmod 644 /etc/profile.d/nodejs.sh

    echo "==> Verifying installation"
    /opt/nodejs/bin/node --version >/dev/null
    if ! command -v node >/dev/null 2>&1; then
        echo "ERROR: 'node' is not on PATH after installation" >&2
        ls -l /usr/local/bin/node /usr/bin/node || true
        exit 1
    fi
    node --version >/dev/null

    echo "==> Cleanup"
    DEBIAN_FRONTEND=noninteractive apt-get purge -y xz-utils curl || true
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
    apt-get clean
    rm -rf /var/lib/apt/lists/* "${tmp_tar}"
}

install_nodejs
