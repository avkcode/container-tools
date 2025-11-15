#!/usr/bin/env bash

MAVEN_VERSION="${MAVEN_VERSION:-3.8.8}"
MAVEN_SHA="${MAVEN_SHA:-332088670d14fa9ff346e6858ca0acca304666596fec86eea89253bd496d3c90deae2be5091be199f48e09d46cec817c6419d5161fb4ee37871503f472765d00}"
MAVEN_URL="${MAVEN_URL:-https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz}"

maven() {
    if [[ ! -f ${DOWNLOAD}/maven-${MAVEN_VERSION}.tar.gz ]]; then
        download ${MAVEN_URL} maven-${MAVEN_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${MAVEN_SHA} ${DOWNLOAD}/maven-${MAVEN_VERSION}.tar.gz sha512sum
    run mkdir --parents "$target"/opt/maven
    run tar -xzf ${DOWNLOAD}/maven-${MAVEN_VERSION}.tar.gz --strip-components=1 --directory "$target"/opt/maven
    
    # https://maven.apache.org/configure.html
    echo -e '\n### MAVEN ###' >> "$target"/root/.bashrc
    echo 'export MAVEN_HOME=/opt/maven' >> "$target"/root/.bashrc
    echo 'export PATH=$PATH:$MAVEN_HOME/bin:$PATH' >> "$target"/root/.bashrc
    echo 'export MAVEN_OPTS="-Xms256m -Xmx1024m"' >> "$target"/root/.bashrc
}
