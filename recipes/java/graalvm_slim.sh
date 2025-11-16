#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

# Defaults can be overridden via environment
GRAALVM_VERSION="${GRAALVM_VERSION:-20.0.2}"
GRAALVM_SHA="${GRAALVM_SHA:-941a85a690e7b1c4e1fcfac321561ca46033bba3ac4882dd15d4f45edd06726c}"
GRAALVM_URL="${GRAALVM_URL:-https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz}"

# Gradle defaults (install Gradle to provide gradle CLI in the image)
GRADLE_VERSION="${GRADLE_VERSION:-7.4.2}"
GRADLE_SHA="${GRADLE_SHA:-29e49b10984e585d8118b7d0bc452f944e386458df27371b49b4ac1dec4b7fda}"
GRADLE_URL="${GRADLE_URL:-https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip}"

ensure_tools_gradle() {
    local need_update=0
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        apt-get update
        apt-get install --yes --no-install-recommends ca-certificates curl
        need_update=1
    fi
    if ! command -v unzip >/dev/null 2>&1 && ! command -v bsdtar >/dev/null 2>&1; then
        [[ "$need_update" -eq 1 ]] || apt-get update
        apt-get install --yes --no-install-recommends unzip
    fi
}

install_gradle_inline() {
    ensure_tools_gradle

    tmpfile="$(mktemp "/tmp/gradle-${GRADLE_VERSION}.XXXXXX.zip")"
    trap 'rm -f "$tmpfile"' EXIT

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --output "$tmpfile" "$GRADLE_URL"
    else
        wget --quiet --output-document="$tmpfile" "$GRADLE_URL"
    fi

    if ! echo "${GRADLE_SHA}  ${tmpfile}" | sha256sum --check --status; then
        echo "ERROR: Gradle checksum verification failed" >&2
        exit 1
    fi

    mkdir -p /opt
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$tmpfile" -d /opt
    else
        bsdtar -xf "$tmpfile" -C /opt
    fi

    if [[ -d "/opt/gradle-${GRADLE_VERSION}" ]]; then
        mv "/opt/gradle-${GRADLE_VERSION}" /opt/gradle
    fi

    mkdir -p /usr/local/bin /usr/bin
    chmod +x /opt/gradle/bin/gradle || true
    ln -sf /opt/gradle/bin/gradle /usr/local/bin/gradle
    ln -sf /opt/gradle/bin/gradle /usr/bin/gradle

    # Fallback wrapper to ensure gradle is on PATH even if symlinks break
    if [ ! -x /usr/bin/gradle ]; then
        printf '%s\n' '#!/bin/sh' 'exec /opt/gradle/bin/gradle "$@"' > /usr/bin/gradle
        chmod 0755 /usr/bin/gradle
    fi

    mkdir -p /etc/profile.d
    cat > /etc/profile.d/gradle.sh <<'EOF'
# Gradle environment
export GRADLE_HOME=/opt/gradle
export PATH="$PATH:$GRADLE_HOME/bin"
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info"
EOF

    # Verify gradle is runnable
    if ! /opt/gradle/bin/gradle --version >/dev/null 2>&1 && ! /usr/local/bin/gradle --version >/dev/null 2>&1; then
        echo "WARNING: gradle installed but not runnable at build time" >&2
    fi

    rm -f "$tmpfile"
}

graalvm_slim() {
    # Ensure network/tools available in chroot
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        apt-get update
        apt-get install --yes --no-install-recommends ca-certificates curl
    fi
    if ! command -v tar >/dev/null 2>&1; then
        apt-get update
        apt-get install --yes --no-install-recommends tar
    fi

    tmp_tgz="$(mktemp "/tmp/graalvm-${GRAALVM_VERSION}.XXXXXX.tgz")"
    trap 'rm -f "$tmp_tgz"' EXIT

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --output "$tmp_tgz" "$GRAALVM_URL"
    else
        wget --quiet --output-document="$tmp_tgz" "$GRAALVM_URL"
    fi

    if ! echo "${GRAALVM_SHA}  ${tmp_tgz}" | sha256sum --check --status; then
        echo "ERROR: GraalVM checksum verification failed" >&2
        exit 1
    fi

    mkdir -p /tmp
    tar -xzf "$tmp_tgz" -C /tmp

    # Avoid SIGPIPE under 'set -o pipefail' by not piping tar output to head
    tar_list="$(tar -tzf "$tmp_tgz")"
    extract_dir="$(printf '%s\n' "$tar_list" | head -n 1 | cut -d/ -f1)"
    if [[ -z "$extract_dir" || ! -d "/tmp/${extract_dir}" ]]; then
        echo "ERROR: Could not determine GraalVM extract directory" >&2
        exit 1
    fi

    mkdir -p /tmp/graal
    mv "/tmp/${extract_dir}"/* /tmp/graal

    # Prepare environment for jlink to find libjli.so
    export JAVA_HOME=/tmp/graal
    export PATH="$JAVA_HOME/bin:$PATH"
    export LD_LIBRARY_PATH="$JAVA_HOME/lib:$JAVA_HOME/lib/jli:$JAVA_HOME/lib/server:${LD_LIBRARY_PATH:-}"

    # Build slim runtime
    "$JAVA_HOME/bin/jlink" \
        --add-modules ALL-MODULE-PATH \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=2 \
        --vm=server \
        --output /opt/graal

    # Cleanup temp files and extracted JDK
    rm -rf "/tmp/${extract_dir}" /tmp/graal "$tmp_tgz" || true

    # Configure environment
    {
      echo ''
      echo '### GRAAL ###'
      echo 'export GRAALVM_HOME=/opt/graal'
      echo 'export JAVA_HOME=$GRAALVM_HOME'
      echo 'export PATH=$GRAALVM_HOME/bin:$PATH'
    } >> /root/.bashrc

    # Ensure gradle is in PATH for interactive shells
    {
      echo ''
      echo '### GRADLE ###'
      echo 'export GRADLE_HOME=/opt/gradle'
      echo 'export PATH=$GRADLE_HOME/bin:$PATH'
    } >> /root/.bashrc

    # Convenience symlinks
    ln -sf /opt/graal/bin/java /usr/local/bin/java || true
    ln -sf /opt/graal/bin/javac /usr/local/bin/javac || true

    # Install Gradle to provide gradle CLI in the image (can be skipped with INSTALL_GRADLE=0)
    if [ "${INSTALL_GRADLE:-1}" = "1" ]; then
        install_gradle_inline
    fi
}

# Execute installation
graalvm_slim
