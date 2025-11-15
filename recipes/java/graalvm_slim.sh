#!/usr/bin/env bash

GRAALVM_VERSION="${GRAALVM_VERSION:-20.0.2}"
GRAALVM_SHA="${GRAALVM_SHA:-941a85a690e7b1c4e1fcfac321561ca46033bba3ac4882dd15d4f45edd06726c}"
GRAALVM_URL="${GRAALVM_URL:-https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz}"

graalvm_slim() {
    if [[ ! -f ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz ]]; then
        download ${GRAALVM_URL} graal-${GRAALVM_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${GRAALVM_SHA} ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz --directory "$target"/tmp
    run mkdir --parents "$target"/tmp/graal
    run mv "$target"/tmp/graalvm-community-openjdk-${GRAALVM_VERSION}+9.1/* "$target"/tmp/graal

    # https://www.oracle.com/corporate/features/understanding-java-9-modules.html
    # https://docs.oracle.com/javase/9/tools/jlink.htm
    run "$target"/tmp/graal/bin/jlink \
                                     --add-modules ALL-MODULE-PATH \
                                     --strip-debug \
                                     --no-man-pages \
                                     --no-header-files \
                                     --compress=2 \
                                     --vm=server \
                                     --output "$target"/opt/graal

    run rm --recursive --force "$target"/tmp/*

    echo -e '\n### GRAAL ###' >> "$target"/root/.bashrc
    echo 'export GRAALVM_HOME=/opt/graal' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=$GRAALVM_HOME' >> "$target"/root/.bashrc
    echo 'export PATH=$GRAALVM_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}
