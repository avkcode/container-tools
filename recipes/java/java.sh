#!/usr/bin/env bash

JDK_VERSION='21.0.1'
JDK_SHA='7e80146b2c3f719bf7f56992eb268ad466f8854d5d6ae11805784608e458343f'
JDK_URL="https://download.java.net/java/GA/jdk${JDK_VERSION}/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"

java() {
    if [[ ! -f ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz ]]; then
        download ${JDK_URL} jdk-${JDK_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${JDK_SHA} ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz --directory "$target"/tmp
    run mkdir --parents "$target"/opt/jdk
    run mv "$target"/tmp/jdk-${JDK_VERSION}/* "$target"/opt/jdk

    run find "$target"/opt/jdk/bin -type f ! -path "./*"/java-rmi.cgi -exec strip --strip-all {} \;
    run find "$target"/opt/jdk -name "*.so*" -exec strip --strip-all {} \;
    run find "$target"/opt/jdk -name jexec -exec strip --strip-all {} \;
    run find "$target"/opt/jdk -name "*.debuginfo" -exec rm --force {} \;
    run find "$target"/opt/jdk -name "*src*zip" -exec rm --force {} \;

    run rm --recursive --force "$target"/opt/jdk/bin/appletviewer
    run rm --recursive --force "$target"/opt/jdk/bin/extcheck
    run rm --recursive --force "$target"/opt/jdk/bin/idlj
    run rm --recursive --force "$target"/opt/jdk/bin/jarsigner
    run rm --recursive --force "$target"/opt/jdk/bin/javah
    run rm --recursive --force "$target"/opt/jdk/bin/javap
    run rm --recursive --force "$target"/opt/jdk/bin/jconsole
    run rm --recursive --force "$target"/opt/jdk/bin/jdmpview
    run rm --recursive --force "$target"/opt/jdk/bin/jdb
    run rm --recursive --force "$target"/opt/jdk/bin/jhat
    run rm --recursive --force "$target"/opt/jdk/bin/jjs
    run rm --recursive --force "$target"/opt/jdk/bin/jmap
    run rm --recursive --force "$target"/opt/jdk/bin/jrunscript
    run rm --recursive --force "$target"/opt/jdk/bin/jstack
    run rm --recursive --force "$target"/opt/jdk/bin/jstat
    run rm --recursive --force "$target"/opt/jdk/bin/jstatd
    run rm --recursive --force "$target"/opt/jdk/bin/native2ascii
    run rm --recursive --force "$target"/opt/jdk/bin/orbd
    run rm --recursive --force "$target"/opt/jdk/bin/policytool
    run rm --recursive --force "$target"/opt/jdk/bin/rmic
    run rm --recursive --force "$target"/opt/jdk/bin/tnameserv
    run rm --recursive --force "$target"/opt/jdk/bin/schemagen
    run rm --recursive --force "$target"/opt/jdk/bin/serialver
    run rm --recursive --force "$target"/opt/jdk/bin/servertool
    run rm --recursive --force "$target"/opt/jdk/bin/tnameserv
    run rm --recursive --force "$target"/opt/jdk/bin/traceformat
    run rm --recursive --force "$target"/opt/jdk/bin/wsgen
    run rm --recursive --force "$target"/opt/jdk/bin/wsimport
    run rm --recursive --force "$target"/opt/jdk/bin/xjc
    
    run rm --recursive --force "$target"/opt/jdk/jmods/java.activation.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.corba.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.transaction.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.xml.ws.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.xml.ws.annotation.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.desktop.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.datatransfer.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/jdk.scripting.nashorn.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/jdk.scripting.nashorn.shell.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/jdk.jconsole.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.scripting.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.se.ee.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.se.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.sql.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.sql.rowset.jmod
    
    run rm --recursive --force "$target"/opt/jdk/lib/jexec

    # https://docs.oracle.com/cd/E19182-01/820-7851/inst_cli_jdk_javahome_t/
    echo -e '\n### JAVA ###' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=/opt/jdk' >> "$target"/root/.bashrc
    echo 'export CLASSPATH=.:$JAVA_HOME/lib/' >> "$target"/root/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}
