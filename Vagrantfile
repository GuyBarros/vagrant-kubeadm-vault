# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provider "parallels" do |p, o|
      p.memory = "1024"
    end
    # Increase memory for Virtualbox
    config.vm.provider "virtualbox" do |vb|
          vb.memory = "1024"
    end
    # Increase memory for VMware
    ["vmware_fusion", "vmware_workstation"].each do |p|
      config.vm.provider p do |v|
        v.vmx["memsize"] = "1024"
        v.vmx["numvcpus"] = "2"
      end
    end
  #  config.vm.provision "shell", path: "bootstrap.sh"

  #  # Load Balancer Node
  #  config.vm.define "loadbalancer" do |lb|
  #    lb.vm.box = "bento/ubuntu-20.04"
  #    lb.vm.hostname = "loadbalancer.example.com"
  #    lb.vm.network "private_network", ip: "172.16.16.100"
  #    lb.vm.provider "virtualbox" do |v|
  #      v.name = "loadbalancer"
  #      v.memory = 1024
  #      v.cpus = 1
  #    end
  #  end
  JumpCount = 1
  # Kubernetes Master Nodes
  (1..JumpCount).each do |i|
    config.vm.define "kjump#{i}" do |jumpnode|
      jumpnode.vm.box = "bento/ubuntu-20.04"
      jumpnode.vm.hostname = "kjump#{i}.example.com"
      jumpnode.vm.network "private_network", ip: "172.16.16.10#{i}"

      jumpnode.vm.provision "shell", path: "bootstrap.sh"
    end
  end

  MasterCount = 1
  # Kubernetes Master Nodes
  (1..MasterCount).each do |i|
    config.vm.define "kmaster#{i}" do |masternode|
      masternode.vm.box = "bento/ubuntu-20.04"
      masternode.vm.hostname = "kmaster#{i}.example.com"
      masternode.vm.network "private_network", ip: "172.16.16.10#{i}"

      masternode.vm.provision "shell", path: "bootstrap.sh"
    end
  end

  NodeCount = 2

  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker#{i}" do |workernode|
      workernode.vm.box = "bento/ubuntu-20.04"
      workernode.vm.hostname = "kworker#{i}.example.com"
      workernode.vm.network "private_network", ip: "172.16.16.20#{i}"

      workernode.vm.provision "shell", path: "bootstrap.sh"
    end
  end

end
