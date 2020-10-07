#!/bin/bash

# disable swapp
sudo swapoff -a

# Letting iptables see bridged traffic
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# install helpful packages
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    jq

# (Install Docker CE)
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update && sudo apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

# Add Docker's official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker apt repository:
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

# Install Docker CE
sudo apt-get update && sudo apt-get install -y \
  containerd.io=1.2.13-2 \
  docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)

# Set up the Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo systemctl enable docker

#Installing kubeadm, kubelet and kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#pull kubeadm images
kubeadm config images pull

#install vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 sudo apt-get update && sudo apt-get install vault


#set Vault address and Vault token enviroment variables
export VAULT_ADDR=http://desktop-khfd9va.lan:8200
export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT
#ca-key.pem
#ca.pem
################################## CHANGE THIS LATER TO USE VAULT AGENT #######################################################################
# CA
#####################
#
# apiserver.crt              apiserver.key                 ca.crt  front-proxy-ca.crt      front-proxy-client.key
# apiserver-etcd-client.crt  apiserver-kubelet-client.crt  ca.key  front-proxy-ca.key      sa.key
# apiserver-etcd-client.key  apiserver-kubelet-client.key  etcd    front-proxy-client.crt  sa.pub
###
vault write -format=json pki_int/issue/leaf-cert common_name="kubernetes" ttl="24h" > ca.json
cat ca.json | jq -r .data.certificate > ca-cert.pem
cat ca.json | jq -r .data.issuing_ca > ca.pem
cat ca.json | jq -r .data.private_key > ca-key.pem
rm ca.json
# Admin
vault write -format=json pki_int/issue/leaf-cert common_name="admin" ttl="24h" > admin.json
cat admin.json | jq -r .data.certificate > admin.pem
cat admin.json | jq -r .data.private_key > admin-key.pem
rm admin.json
# Nodes
NODES=4
for (( S=0; S<=$NODES; S++ )); do
vault write -format=json pki_int/issue/leaf-cert common_name="node$S" ttl="24h" > node$S.json
cat node$S.json | jq -r .data.certificate > node$S.pem
cat node$S.json | jq -r .data.private_key > node$S-key.pem
rm node$S.json
done


