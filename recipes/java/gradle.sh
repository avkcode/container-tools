#!/usr/bin/env bash

GRADLE_VERSION='7.4.2'
GRADLE_SHA='29e49b10984e585d8118b7d0bc452f944e386458df27371b49b4ac1dec4b7fda'
GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

gradle() {
    if [[ ! -f ${DOWNLOAD}/gradle-${GRADLE_VERSION}-bin.zip ]]; then
        download ${GRADLE_URL} gradle-${GRADLE_VERSION}-bin.zip ${DOWNLOAD}
    fi
    check_sum ${GRADLE_SHA} ${DOWNLOAD}/gradle-${GRADLE_VERSION}-bin.zip
    run unzip ${DOWNLOAD}/gradle-${GRADLE_VERSION}-bin.zip -d "$target"/opt
    run mv "$target"/opt/gradle-${GRADLE_VERSION} "$target"/opt/gradle

    # https://docs.gradle.org/current/userguide/build_environment.html#sec:gradle_environment_variables
    echo -e '\n ### GRADLE ###' >> "$target"/root/.bashrc
    echo 'export GRADLE_HOME=/opt/gradle' >> "$target"/root/.bashrc
    echo 'export PATH=$PATH:$GRADLE_HOME/bin:$PATH' >> "$target"/root/.bashrc
    echo 'export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info"' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}
