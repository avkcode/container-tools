#!/usr/bin/env bash

# Node.js Current (23.x) version
NODE_VERSION="${NODE_VERSION:-23.11.0}"
NODE_SHA="${NODE_SHA:-fa9ae28d8796a6cfb7057397e1eea30ca1c61002b42b8897f354563a254e7cf5}"
NODE_URL="${NODE_URL:-https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz}"

nodejs() {
    # Install required tools inside target chroot (avoid host modifications)
    run chroot "$target" apt-get update
    run chroot "$target" apt-get install -y --no-install-recommends xz-utils ca-certificates
    
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

    # Clean up apt cache and temporary files inside target
    run chroot "$target" apt-get purge -y xz-utils
    run chroot "$target" apt-get autoremove -y
    run chroot "$target" apt-get clean
    run rm -rf "$target"/var/lib/apt/lists/*

    # Write environment variables to profile.d for container runtime
    run install -d -m 0755 "$target/etc/profile.d"
    cat > "$target/etc/profile.d/nodejs.sh" <<'EOF'
export NODE_HOME=/opt/nodejs
export PATH=$NODE_HOME/bin:$PATH
EOF
    run chmod 644 "$target/etc/profile.d/nodejs.sh"
}
