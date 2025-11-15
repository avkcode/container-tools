#!/usr/bin/env bash
set -o errexit
set -o pipefail

# Defaults can be overridden via environment
MAVEN_VERSION="${MAVEN_VERSION:-3.8.8}"
MAVEN_SHA="${MAVEN_SHA:-332088670d14fa9ff346e6858ca0acca304666596fec86eea89253bd496d3c90deae2be5091be199f48e09d46cec817c6419d5161fb4ee37871503f472765d00}"
MAVEN_URL="${MAVEN_URL:-https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz}"

maven() {
    # Download Maven tarball into chroot temp
    tmpfile="$(mktemp /tmp/maven-${MAVEN_VERSION}.XXXXXX.tar.gz)"
    trap 'rm -f "$tmpfile"' EXIT

    curl --fail --location --silent --show-error --output "$tmpfile" "$MAVEN_URL"

    # Verify SHA512 checksum
    if ! echo "${MAVEN_SHA}  ${tmpfile}" | sha512sum --check --status; then
        echo "ERROR: Maven checksum verification failed" >&2
        exit 1
    fi

    # Install Maven under /opt and make it available on PATH
    mkdir -p /opt/maven
    tar -xzf "$tmpfile" --strip-components=1 --directory /opt/maven

    # Ensure mvn is discoverable even without profile scripts
    mkdir -p /usr/local/bin
    ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn

    # Configure environment for login shells
    mkdir -p /etc/profile.d
    cat > /etc/profile.d/maven.sh <<'EOF'
# Maven environment
export MAVEN_HOME=/opt/maven
export PATH="$PATH:$MAVEN_HOME/bin"
export MAVEN_OPTS="-Xms256m -Xmx1024m"
EOF

    # Cleanup download
    rm -f "$tmpfile"
}

# Execute installation
maven
