#!/usr/bin/env bash

# Node.js LTS version
NODE_VERSION="${NODE_VERSION:-23.11.0}"
NODE_SHA="${NODE_SHA:-fa9ae28d8796a6cfb7057397e1eea30ca1c61002b42b8897f354563a254e7cf5}"
NODE_URL="${NODE_URL:-https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz}"

nodejs() {
    # Install required tools
    run apt-get update
    run apt-get install -y xz-utils ca-certificates
    
    # Download Node.js
    if [[ ! -f ${DOWNLOAD}/node-v${NODE_VERSION}.tar.xz ]]; then
        download ${NODE_URL} node-v${NODE_VERSION}.tar.xz ${DOWNLOAD}
    fi
    
    # Verify checksum
    check_sum ${NODE_SHA} ${DOWNLOAD}/node-v${NODE_VERSION}.tar.xz

    # Install Node.js
    run mkdir -p "$target"/opt/nodejs
    run tar -xJf ${DOWNLOAD}/node-v${NODE_VERSION}.tar.xz \
       --strip-components=1 \
       --directory "$target"/opt/nodejs

    # Verify the binaries exist before creating symlinks
    if [[ ! -f "$target"/opt/nodejs/bin/node ]]; then
        die "Node.js binary not found after extraction"
    fi

    # Create symlinks using absolute paths
    run ln -sf /opt/nodejs/bin/node "$target"/usr/bin/node
    run ln -sf /opt/nodejs/bin/npm "$target"/usr/bin/npm
    run ln -sf /opt/nodejs/bin/npx "$target"/usr/bin/npx

    # Verify installation by calling the absolute path
    if ! chroot "$target" /opt/nodejs/bin/node --version; then
        die "Node.js verification failed"
    fi

    # Clean up apt cache and temporary files
    run apt-get remove -y xz-utils
    run apt-get autoremove -y
    run apt-get clean
    run rm -rf /var/lib/apt/lists/*

    # Set up environment variables (for when container runs)
    echo 'export PATH=/opt/nodejs/bin:$PATH' >> "$target"/etc/profile
    echo 'export NODE_HOME=/opt/nodejs' >> "$target"/etc/profile
}
