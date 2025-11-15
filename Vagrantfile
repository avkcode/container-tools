LINUX_BOX = ENV.fetch("VAGRANT_BOX", "ubuntu/jammy64")
CPUS      = ENV.fetch("CPUS", "2")
MEMORY    = ENV.fetch("MEMORY", "2048")

Vagrant.configure(2) do |config|
  config.vm.define "containerImages", autostart: true, primary: true do |cfg|
    cfg.vm.box = LINUX_BOX
    cfg.vm.hostname = "containerImages"

    cfg = configureProviders cfg,
      cpus: CPUS,
      memory: MEMORY

    cfg.vm.synced_folder '../','/opt/containerImages'

    cfg.vm.provision "shell", privileged: true, inline: <<-SHELL
      set -euo pipefail
      export DEBIAN_FRONTEND=noninteractive

      if ! command -v apt-get >/dev/null 2>&1; then
        echo "This provisioner expects an Ubuntu/Debian guest."
        exit 0
      fi

      apt-get update -y

      apt-get install -y --no-install-recommends \
        ca-certificates curl unzip make gnupg lsb-release software-properties-common \
        docker.io podman debootstrap cosign

      if getent group docker >/dev/null 2>&1; then
        usermod -aG docker vagrant || true
      end

      if ! command -v trivy >/dev/null 2>&1; then
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
      fi

      if ! command -v container-structure-test >/dev/null 2>&1; then
        cst_url="https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64"
        curl -L "$cst_url" -o /usr/local/bin/container-structure-test
        chmod +x /usr/local/bin/container-structure-test
      fi

      systemctl enable --now docker || true
    SHELL
  end

  def configureProviders(config, cpus: "2", memory: "2048")
    config.vm.provider "vmware_desktop" do |v|
      v.memory = memory
      v.cpus = cpus
      v.ssh_info_public = true
      v.gui = false
    end

    config.vm.provider "virtualbox" do |vb|
      vb.memory = memory
      vb.cpus = cpus
      vb.gui = false
    end

    config.vm.provider "libvirt" do |lv|
      lv.memory = memory
      lv.cpus = cpus
      # GUI not applicable for libvirt in headless setups
    end

    config
  end
end
