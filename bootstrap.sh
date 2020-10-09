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


# set Vault address and Vault token enviroment variables
# these are all dynamically generated so it doesnt matter so much that they are on GITHUB :)
#export VAULT_ADDR=http://desktop-khfd9va.lan:8200
#export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT
export VAULT_ADDR=https://vault.eu-guystack.original.aws.hashidemos.io:8200
export VAULT_TOKEN=${VAULT_TOKEN}
# set VAULT_ADDR=https://vault.eu-guystack.original.aws.hashidemos.io:8200
# set VAULT_TOKEN=${VAULT_TOKEN}

#ca-key.pem
#ca.pem
################################## CHANGE THIS LATER TO USE VAULT AGENT #######################################################################
# CA
#####################
#
sudo mkdir /etc/kubernetes/pki
sudo mkdir /etc/kubernetes/pki/etcd
################################## CHANGE THIS LATER TO USE VAULT AGENT #######################################################################
#       front-proxy-client.key
#       sa.key
# front-proxy-client.crt  sa.pub
##### KUBERNETES ##  openssl x509 -in peer.crt -text -noout
# CA
vault write -format=json kubernetes_int/issue/kubernetes-ca common_name="kubernetes-ca" ttl="24h" > kubernetes-ca.json
cat kubernetes-ca.json | jq -r .data.certificate > ca.crt
cat kubernetes-ca.json | jq -r .data.private_key > ca.key
rm kubernetes-ca.json
# APISERVER
vault write -format=json kubernetes_int/issue/kubernetes-ca common_name="kube-apiserver" ip_sans="127.0.0.1,172.16.16.111,10.96.0.1,192.168.225.193" alt_names="localhost,kjump1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local" ttl="24h" > apiserver.json
cat apiserver.json | jq -r .data.certificate > apiserver.crt
cat apiserver.json | jq -r .data.private_key > apiserver.key
rm apiserver.json
# APISERVER-KUBELET-CLIENT
vault write -format=json kubernetes_int/issue/kube-apiserver-kubelet-client common_name="kube-apiserver-kubelet-client" ip_sans="127.0.0.1,172.16.16.111,10.96.0.1,192.168.225.193" alt_names="localhost,kjump1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local" ttl="24h" > apiserver-kubelet-client.json
cat apiserver-kubelet-client.json | jq -r .data.certificate > apiserver-kubelet-client.crt
cat apiserver-kubelet-client.json | jq -r .data.private_key > apiserver-kubelet-client.key
rm apiserver-kubelet-client.json
# APISERVER-ETCD-CLIENT
vault write -format=json etcd_int/issue/kube-apiserver-etcd-client common_name="kube-apiserver-kubelet-client"  ttl="24h" > kube-apiserver-etcd-client.json
cat kube-apiserver-etcd-client.json | jq -r .data.certificate > kube-apiserver-etcd-client.crt
cat kube-apiserver-etcd-client.json | jq -r .data.private_key > kube-apiserver-etcd-client.key
rm kube-apiserver-etcd-client.json
##### ETCD
ca.crt  ca.key  healthcheck-client.crt  healthcheck-client.key  peer.crt  peer.key  server.crt  server.key
# CA
vault write -format=json etcd_int/issue/etcd-ca common_name="etcd-ca"  ttl="24h" > etcd-ca.json
cat etcd-ca.json | jq -r .data.certificate > ca.crt
cat etcd-ca.json | jq -r .data.private_key > ca.key
rm etcd-ca.json
# healthcheck-client
vault write -format=json etcd_int/issue/kube-etcd-healthcheck-client common_name="kube-etcd-healthcheck-client"  ttl="24h" > healthcheck-client.json
cat healthcheck-client.json | jq -r .data.certificate > healthcheck-client.crt
cat healthcheck-client.json | jq -r .data.private_key > healthcheck-client.key
rm healthcheck-client.json
# peer
vault write -format=json etcd_int/issue/kube-etcd-peer common_name="kjump1" ip_sans="127.0.0.1,192.168.225.193" alt_names="localhost,kjump1"  ttl="24h" > kube-etcd-peer.json
cat kube-etcd-peer.json | jq -r .data.certificate > peer.crt
cat kube-etcd-peer.json | jq -r .data.private_key > peer.key
rm kube-etcd-peer.json
# server
vault write -format=json etcd_int/issue/etcd-ca common_name="kjump1" ip_sans="127.0.0.1,192.168.225.193" alt_names="localhost,kjump1"  ttl="24h" > server.json
cat server.json | jq -r .data.certificate > server.crt
cat server.json | jq -r .data.private_key > server.key
rm server.json
##### PROXY
# front-proxy-ca
vault write -format=json proxy_int/issue/front-proxy-ca common_name="front-proxy-ca"  ttl="24h" > front-proxy-ca.json
cat front-proxy-ca.json | jq -r .data.certificate > front-proxy-ca.crt
cat front-proxy-ca.json | jq -r .data.private_key > front-proxy-ca.key
rm front-proxy-ca.json
# front-proxy-client
vault write -format=json proxy_int/issue/front-proxy-ca common_name="front-proxy-client"  ttl="24h" > front-proxy-client.json
cat front-proxy-client.json | jq -r .data.certificate > front-proxy-client.crt
cat front-proxy-client.json | jq -r .data.private_key > front-proxy-client.key
rm front-proxy-client.json
