FROM quay.io/official-images/debian

RUN apt-get update && apt-get install -y curl debootstrap gpg make binutils unzip
RUN apt-get install -y wget apt-transport-https gnupg lsb-release \
    && wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - \
    && echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy

# Install Alpine Linux tools
RUN apt-get install -y alpine-chroot-install \
    && mkdir -p /etc/apk \
    && mkdir -p /lib/apk \
    && mkdir -p /var/cache/apk
