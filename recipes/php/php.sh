#!/usr/bin/env bash

# PHP version and download details
PHP_VERSION='8.4.6'
PHP_SHA='089b08a5efef02313483325f3bacd8c4fe311cf1e1e56749d5cc7d059e225631'
PHP_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz"


php() {
    header "Installing build dependencies"
    local build_deps=(
        build-essential
        pkg-config
        libxml2-dev
        libsqlite3-dev
        libcurl4-openssl-dev
        libonig-dev
        libssl-dev
        zlib1g-dev
        libzip-dev
        libreadline-dev
    )
    run apt-get update
    run apt-get install -y --no-install-recommends "${build_deps[@]}"

    header "Downloading PHP ${PHP_VERSION}"
    if [[ ! -f "${DOWNLOAD}/php-${PHP_VERSION}.tar.xz" ]]; then
        download "${PHP_URL}" "php-${PHP_VERSION}.tar.xz" "${DOWNLOAD}" ||
            die "Failed to download PHP"
    fi
    check_sum "${PHP_SHA}" "${DOWNLOAD}/php-${PHP_VERSION}.tar.xz" ||
        die "Checksum verification failed"

    header "Building PHP ${PHP_VERSION}"
    run mkdir -p "${DOWNLOAD}/php-build"
    run tar -xJf "${DOWNLOAD}/php-${PHP_VERSION}.tar.xz" -C "${DOWNLOAD}/php-build" --strip-components=1

    pushd "${DOWNLOAD}/php-build" >/dev/null

    # Configure PHP with common production settings
    ./configure \
        --prefix=/usr \
        --with-config-file-path=/etc/php \
        --with-config-file-scan-dir=/etc/php/conf.d \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --enable-mbstring \
        --enable-zip \
        --enable-bcmath \
        --enable-pcntl \
        --enable-ftp \
        --enable-exif \
        --enable-calendar \
        --with-openssl \
        --with-curl \
        --with-zlib \
        --with-zip \
        --with-pear \
        --with-readline \
        --enable-opcache \
        --without-sqlite3 \
        --with-pdo-sqlite \
        --enable-mysqlnd \
        --without-pdo-sqlite

    # Build with limited parallelism
    run make -j$(($(nproc)/2)) || run make

    # Install into target
    run make install DESTDIR="$target"
    popd >/dev/null

    header "Configuring PHP"
    # Create directory structure
    run mkdir -p "$target/etc/php/conf.d"
    run mkdir -p "$target/var/log/php"
    run mkdir -p "$target/var/run/php"

    # Create default php.ini files
    cat > "$target/etc/php/php.ini" <<EOF
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = Off
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 2M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60

[CLI Server]
cli_server.color = On

[Date]
date.timezone = UTC

[filter]
[iconv]
[intl]
[sqlite]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.default_socket=

[Phar]
[mail function]
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On

[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1

[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off

[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0

[bcmath]
bcmath.scale = 0

[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly = 1
session.cookie_samesite =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.sid_length = 26
session.trans_sid_tags = "a=href,area=href,frame=src,form="
session.sid_bits_per_character = 5

[Assertion]
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off

[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5

[sysvshm]
[ldap]
ldap.max_links = -1

[dba]
[opcache]
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.save_comments=1
EOF

    # Create PHP-FPM config
    cat > "$target/etc/php/php-fpm.conf" <<EOF
[global]
pid = /var/run/php/php-fpm.pid
error_log = /var/log/php/php-fpm.log
log_level = notice
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes

[www]
user = www-data
group = www-data
listen = 127.0.0.1:9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
slowlog = /var/log/php/php-slow.log
request_slowlog_timeout = 5s
request_terminate_timeout = 30s
catch_workers_output = yes
EOF

    # Create environment setup
    echo -e '\n### PHP ###' >> "$target"/root/.bashrc
    echo 'export PATH=/usr/bin:$PATH' >> "$target"/root/.bashrc

    # Create symlinks
    run ln -sf /usr/bin/php "$target"/usr/local/bin/php
    run ln -sf /usr/sbin/php-fpm "$target"/usr/local/sbin/php-fpm

    header "Cleaning up"
    run apt-get purge -y "${build_deps[@]}"
    run apt-get autoremove -y
    run apt-get clean
    run rm -rf "${DOWNLOAD}/php-build" /var/lib/apt/lists/*

    header "Verifying installation"
    if [ -f "$target/usr/bin/php" ]; then
        info "PHP found at /usr/bin/php"
        chroot "$target" /usr/bin/php --version
    else
        die "PHP installation failed - binary not found"
    fi

    info "PHP ${PHP_VERSION} installed successfully"
}
