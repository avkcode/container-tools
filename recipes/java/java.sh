#!/usr/bin/env bash
set -euo pipefail

JDK_VERSION="${JAVA_VERSION:-21.0.1}"
JDK_SHA="${JAVA_SHA:-7e80146b2c3f719bf7f56992eb268ad466f8854d5d6ae11805784608e458343f}"
JDK_URL="${JAVA_URL:-https://download.java.net/java/GA/jdk${JDK_VERSION}/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz}"

java() {
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
    mkdir -p /opt/jdk
    mv /tmp/jdk-${JDK_VERSION}/* /opt/jdk

    # Strip debug symbols to reduce size (best-effort)
    find /opt/jdk/bin -type f ! -path "./*"/java-rmi.cgi -exec strip --strip-all {} \; || true
    find /opt/jdk -name "*.so*" -exec strip --strip-all {} \; || true
    find /opt/jdk -name jexec -exec strip --strip-all {} \; || true
    find /opt/jdk -name "*.debuginfo" -exec rm -f {} \; || true
    find /opt/jdk -name "*src*zip" -exec rm -f {} \; || true

    # Remove unneeded binaries
    rm -rf /opt/jdk/bin/appletviewer
    rm -rf /opt/jdk/bin/extcheck
    rm -rf /opt/jdk/bin/idlj
    rm -rf /opt/jdk/bin/jarsigner
    rm -rf /opt/jdk/bin/javah
    rm -rf /opt/jdk/bin/javap
    rm -rf /opt/jdk/bin/jconsole
    rm -rf /opt/jdk/bin/jdmpview
    rm -rf /opt/jdk/bin/jdb
    rm -rf /opt/jdk/bin/jhat
    rm -rf /opt/jdk/bin/jjs
    rm -rf /opt/jdk/bin/jmap
    rm -rf /opt/jdk/bin/jrunscript
    rm -rf /opt/jdk/bin/jstack
    rm -rf /opt/jdk/bin/jstat
    rm -rf /opt/jdk/bin/jstatd
    rm -rf /opt/jdk/bin/native2ascii
    rm -rf /opt/jdk/bin/orbd
    rm -rf /opt/jdk/bin/policytool
    rm -rf /opt/jdk/bin/rmic
    rm -rf /opt/jdk/bin/tnameserv
    rm -rf /opt/jdk/bin/schemagen
    rm -rf /opt/jdk/bin/serialver
    rm -rf /opt/jdk/bin/servertool
    rm -rf /opt/jdk/bin/tnameserv
    rm -rf /opt/jdk/bin/traceformat
    rm -rf /opt/jdk/bin/wsgen
    rm -rf /opt/jdk/bin/wsimport
    rm -rf /opt/jdk/bin/xjc

    # Remove selected modules and helpers
    rm -rf /opt/jdk/jmods/java.activation.jmod
    rm -rf /opt/jdk/jmods/java.corba.jmod
    rm -rf /opt/jdk/jmods/java.transaction.jmod
    rm -rf /opt/jdk/jmods/java.xml.ws.jmod
    rm -rf /opt/jdk/jmods/java.xml.ws.annotation.jmod
    rm -rf /opt/jdk/jmods/java.desktop.jmod
    rm -rf /opt/jdk/jmods/java.datatransfer.jmod
    rm -rf /opt/jdk/jmods/jdk.scripting.nashorn.jmod
    rm -rf /opt/jdk/jmods/jdk.scripting.nashorn.shell.jmod
    rm -rf /opt/jdk/jmods/jdk.jconsole.jmod
    rm -rf /opt/jdk/jmods/java.scripting.jmod
    rm -rf /opt/jdk/jmods/java.se.ee.jmod
    rm -rf /opt/jdk/jmods/java.se.jmod
    rm -rf /opt/jdk/jmods/java.sql.jmod
    rm -rf /opt/jdk/jmods/java.sql.rowset.jmod

    rm -rf /opt/jdk/lib/jexec

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
java "$@"
