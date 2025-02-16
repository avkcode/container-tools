#!/usr/bin/env bash

JDK_VERSION='21.0.1'
JDK_SHA='7e80146b2c3f719bf7f56992eb268ad466f8854d5d6ae11805784608e458343f'
JDK_URL="https://download.java.net/java/GA/jdk${JDK_VERSION}/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"

java_slim() {
    if [[ ! -f ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz ]]; then
        download ${JDK_URL} jdk-${JDK_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${JDK_SHA} ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz --directory "$target"/tmp
    run mkdir --parents "$target"/tmp/jdk
    run mv "$target"/tmp/jdk-${JDK_VERSION}/* "$target"/tmp/jdk

    # https://www.oracle.com/corporate/features/understanding-java-9-modules.html
    # https://docs.oracle.com/javase/9/tools/jlink.htm
    run "$target"/tmp/jdk/bin/jlink \
                                     --add-modules ALL-MODULE-PATH \
                                     --strip-java-debug-attributes \
                                     --no-man-pages \
                                     --no-header-files \
                                     --compress=2 \
                                     --vm=server \
                                     --output "$target"/opt/jdk

    run rm --recursive --force "$target"/tmp/*

    # https://docs.oracle.com/cd/E19182-01/820-7851/inst_cli_jdk_javahome_t/
    echo -e '\n### JAVA ###' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=/opt/jdk' >> "$target"/root/.bashrc
    echo 'export CLASSPATH=.:$JAVA_HOME/lib/' >> "$target"/root/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}
