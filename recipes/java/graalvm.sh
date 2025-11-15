#!/usr/bin/env bash

GRAALVM_VERSION="${GRAALVM_VERSION:-20.0.2}"
GRAALVM_SHA="${GRAALVM_SHA:-941a85a690e7b1c4e1fcfac321561ca46033bba3ac4882dd15d4f45edd06726c}"
GRAALVM_URL="${GRAALVM_URL:-https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz}"

graalvm() {
    if [[ ! -f ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz ]]; then
        download ${GRAALVM_URL} graal-${GRAALVM_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${GRAALVM_SHA} ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz --directory "$target"/opt
    run mv "$target"/opt/graalvm-community-openjdk-${GRAALVM_VERSION}+9.1 "$target"/opt/graal/

    run find "$target"/opt/graal/bin -type f ! -path "./*"/java-rmi.cgi -exec strip --strip-all {} \;
    run find "$target"/opt/graal -name "*.so*" -exec strip --strip-all {} \;
    run find "$target"/opt/graal -name jexec -exec strip --strip-all {} \;
    run find "$target"/opt/graal -name "*.debuginfo" -exec rm --force {} \;
    run find "$target"/opt/graal -name "*src*zip" -exec rm --force {} \;

    run rm --recursive --force "$target"/opt/graal/bin/appletviewer
    run rm --recursive --force "$target"/opt/graal/bin/extcheck
    run rm --recursive --force "$target"/opt/graal/bin/idlj
    run rm --recursive --force "$target"/opt/graal/bin/jarsigner
    run rm --recursive --force "$target"/opt/graal/bin/javah
    run rm --recursive --force "$target"/opt/graal/bin/javap
    run rm --recursive --force "$target"/opt/graal/bin/jconsole
    run rm --recursive --force "$target"/opt/graal/bin/jdmpview
    run rm --recursive --force "$target"/opt/graal/bin/jdb
    run rm --recursive --force "$target"/opt/graal/bin/jhat
    run rm --recursive --force "$target"/opt/graal/bin/jjs
    run rm --recursive --force "$target"/opt/graal/bin/jmap
    run rm --recursive --force "$target"/opt/graal/bin/jrunscript
    run rm --recursive --force "$target"/opt/graal/bin/jstack
    run rm --recursive --force "$target"/opt/graal/bin/jstat
    run rm --recursive --force "$target"/opt/graal/bin/jstatd
    run rm --recursive --force "$target"/opt/graal/bin/native2ascii
    run rm --recursive --force "$target"/opt/graal/bin/orbd
    run rm --recursive --force "$target"/opt/graal/bin/policytool
    run rm --recursive --force "$target"/opt/graal/bin/rmic
    run rm --recursive --force "$target"/opt/graal/bin/tnameserv
    run rm --recursive --force "$target"/opt/graal/bin/schemagen
    run rm --recursive --force "$target"/opt/graal/bin/serialver
    run rm --recursive --force "$target"/opt/graal/bin/servertool
    run rm --recursive --force "$target"/opt/graal/bin/tnameserv
    run rm --recursive --force "$target"/opt/graal/bin/traceformat
    run rm --recursive --force "$target"/opt/graal/bin/wsgen
    run rm --recursive --force "$target"/opt/graal/bin/wsimport
    run rm --recursive --force "$target"/opt/graal/bin/xjc
    
    run rm --recursive --force "$target"/opt/graal/jmods/java.activation.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.corba.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.transaction.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.xml.ws.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.xml.ws.annotation.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.desktop.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.datatransfer.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/jdk.scripting.nashorn.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/jdk.scripting.nashorn.shell.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/jdk.jconsole.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.scripting.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.se.ee.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.se.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.sql.jmod
    run rm --recursive --force "$target"/opt/graal/jmods/java.sql.rowset.jmod

    run rm --recursive --force "$target"/opt/graal/lib/jexec

    echo -e '\n### GRAAL ###' >> "$target"/root/.bashrc
    echo 'export GRAALVM_HOME=/opt/graal' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=$GRAALVM_HOME' >> "$target"/root/.bashrc
    echo 'export PATH=$GRAALVM_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}
