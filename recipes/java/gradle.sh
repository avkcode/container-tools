#!/usr/bin/env bash
set -o errexit
set -o pipefail

# Defaults can be overridden via environment
GRADLE_VERSION="${GRADLE_VERSION:-7.4.2}"
GRADLE_SHA="${GRADLE_SHA:-29e49b10984e585d8118b7d0bc452f944e386458df27371b49b4ac1dec4b7fda}"
GRADLE_URL="${GRADLE_URL:-https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip}"

install_gradle() {
    # Download Gradle distribution into a temp file inside the chroot
    tmpfile="$(mktemp "/tmp/gradle-${GRADLE_VERSION}.XXXXXX.zip")"
    trap 'rm -f "$tmpfile"' EXIT

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --output "$tmpfile" "$GRADLE_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --output-document="$tmpfile" "$GRADLE_URL"
    else
        echo "ERROR: Neither curl nor wget is available to download Gradle." >&2
        exit 1
    fi

    # Verify SHA256 checksum
    if ! echo "${GRADLE_SHA}  ${tmpfile}" | sha256sum --check --status; then
        echo "ERROR: Gradle checksum verification failed" >&2
        exit 1
    fi

    # Extract to /opt using whichever tool is available: unzip, bsdtar, or jar
    mkdir -p /opt
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$tmpfile" -d /opt
    elif command -v bsdtar >/dev/null 2>&1; then
        bsdtar -xf "$tmpfile" -C /opt
    elif [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/jar" ]]; then
        mkdir -p /opt/.gradle-extract
        ( cd /opt/.gradle-extract && "${JAVA_HOME}/bin/jar" xf "$tmpfile" )
        mv /opt/.gradle-extract/* /opt/
        rmdir /opt/.gradle-extract
    elif [[ -x "/opt/jdk/bin/jar" ]]; then
        mkdir -p /opt/.gradle-extract
        ( cd /opt/.gradle-extract && /opt/jdk/bin/jar xf "$tmpfile" )
        mv /opt/.gradle-extract/* /opt/
        rmdir /opt/.gradle-extract
    else
        echo "ERROR: Could not find unzip, bsdtar, or jar to extract Gradle." >&2
        exit 1
    fi

    # Normalize install path and expose gradle on PATH
    if [[ -d "/opt/gradle-${GRADLE_VERSION}" ]]; then
        mv "/opt/gradle-${GRADLE_VERSION}" /opt/gradle
    fi
    mkdir -p /usr/local/bin
    ln -sf /opt/gradle/bin/gradle /usr/local/bin/gradle

    # Configure environment for login shells
    mkdir -p /etc/profile.d
    cat > /etc/profile.d/gradle.sh <<'EOF'
# Gradle environment
export GRADLE_HOME=/opt/gradle
export PATH="$PATH:$GRADLE_HOME/bin"
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info"
EOF

    # Cleanup download
    rm -f "$tmpfile"
}

# Execute installation
install_gradle
