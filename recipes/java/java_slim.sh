#!/usr/bin/env bash
set -euo pipefail

JDK_VERSION="${JAVA_VERSION:-21.0.1}"
JDK_SHA="${JAVA_SHA:-7e80146b2c3f719bf7f56992eb268ad466f8854d5d6ae11805784608e458343f}"
JDK_URL="${JAVA_URL:-https://download.java.net/java/GA/jdk${JDK_VERSION}/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz}"

java_slim() {
    # Ensure necessary tools are available in the chroot
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl binutils
    rm -rf /var/lib/apt/lists/*

    # Map Debian arch to JDK archive naming
    arch="$(dpkg --print-architecture)"
    case "$arch" in
      amd64) jdk_arch="x64" ;;
      arm64) jdk_arch="aarch64" ;;
      *) jdk_arch="x64" ;;
    esac

    # Derive URL for current arch when using the default template
    url="${JDK_URL}"
    if [[ "$url" == *"linux-x64_bin.tar.gz" ]]; then
      url="${url/linux-x64_bin.tar.gz/linux-${jdk_arch}_bin.tar.gz}"
    fi

    tmp_tar="/tmp/jdk-${JDK_VERSION}.tar.gz"
    if [[ ! -f "$tmp_tar" ]]; then
      curl -fsSL -o "$tmp_tar" "$url"
    fi

    # Only check the default x64 SHA by default (arm64 SHA differs)
    if [[ "$arch" == "amd64" && -n "${JDK_SHA:-}" ]]; then
      echo "${JDK_SHA}  $tmp_tar" | sha256sum -c -
    fi

    tar -xzf "$tmp_tar" --directory /tmp
    mkdir -p /tmp/jdk
    mv /tmp/jdk-${JDK_VERSION}/* /tmp/jdk

    # Create a slim runtime with jlink
    /tmp/jdk/bin/jlink \
        --add-modules ALL-MODULE-PATH \
        --strip-java-debug-attributes \
        --no-man-pages \
        --no-header-files \
        --compress=2 \
        --vm=server \
        --output /opt/jdk

    # Clean temporary files
    rm -rf /tmp/*

    # Ensure java is available on PATH for all shells
    ln -sf /opt/jdk/bin/java /usr/bin/java

    # Provide JAVA_HOME and PATH via profile.d
    cat >> /etc/profile.d/java.sh <<'EOF'
# Java environment
export JAVA_HOME=/opt/jdk
export CLASSPATH=.:$JAVA_HOME/lib/
export PATH=$JAVA_HOME/bin:$PATH
EOF
    chmod 0644 /etc/profile.d/java.sh
}
java_slim "$@"
