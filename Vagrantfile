LINUX_BOX = "spox/ubuntu-arm"
CPUS = "2"

Vagrant.configure(2) do |config|
    config.vm.define "containerImages", autostart: true, primary: true do |config|
        config.vm.box = LINUX_BOX
        config.vm.hostname = "containerImages"
        config = configureProviders config,
            cpus: CPUS
        config.vm.synced_folder '../','/opt/containerImages'
    end

    def configureProviders(config, cpus: "2", memory: "2048")
        config.vm.provider "vmware_desktop" do |v|
            v.memory = memory
            v.cpus = cpus
            v.ssh_info_public = true
            v.gui = true
        end
        return config
    end
end
