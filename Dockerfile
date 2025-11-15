FROM quay.io/official-images/debian

RUN apt-get update && apt-get install -y --no-install-recommends curl debootstrap gpg make binutils unzip ca-certificates gnupg lsb-release wget apt-transport-https && rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends trivy; \
    curl -fsSL https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 -o /usr/local/bin/cosign; \
    chmod +x /usr/local/bin/cosign; \
    curl -fsSL https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 -o /usr/local/bin/container-structure-test; \
    chmod +x /usr/local/bin/container-structure-test; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

