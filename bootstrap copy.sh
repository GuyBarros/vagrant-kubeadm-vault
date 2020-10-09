#!/bin/bash

# install helpful packages
sudo apt install -y jq

#install kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

#install vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 sudo apt-get update && sudo apt-get install vault


#set Vault address and Vault token enviroment variables
export VAULT_ADDR=http://desktop-khfd9va.lan:8200
export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT
# set VAULT_ADDR=http://desktop-khfd9va.lan:8200
# set VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT

#ca-key.pem
#ca.pem
################################## CHANGE THIS LATER TO USE VAULT AGENT #######################################################################
# https://www.vaultproject.io/api-docs/secret/pki#parameters-6
# kube-etcd
vault write -format=json etcd_int/issue/etcd-ca common_name="etcd-ca" ttl="24h" ip_sans="127.0.0.1,172.16.16.111" alt_names="localhost,kjump1" > etcd-ca.json
cat etcd-ca.json | jq -r .data.certificate > etcd-ca-cert.pem
cat etcd-ca.json | jq -r .data.issuing_ca > etcd-ca.pem
cat etcd-ca.json | jq -r .data.private_key > etcd-ca-key.pem
rm etcd-ca.json

# kube-etcd
vault write -format=json etcd_int/issue/kube-etcd-peer common_name="kube-etcd-peer" ttl="24h" ip_sans="127.0.0.1,172.16.16.111" alt_names="localhost,kjump1" > kube-etcd-peer.json
cat kube-etcd-peer.json | jq -r .data.certificate > kube-etcd-peer-cert.pem
cat kube-etcd-peer.json | jq -r .data.issuing_ca > kube-etcd-peer.pem
cat kube-etcd-peer.json | jq -r .data.private_key > kube-etcd-peer-key.pem
rm kube-etcd-peer.json

# kube-etcd-healthcheck-client
vault write -format=json etcd_int/issue/kube-apiserver-etcd-client common_name="kube-etcd-healthcheck-client" ttl="24h" ip_sans="127.0.0.1,172.16.16.111" alt_names="localhost,kjump1" > kube-etcd-healthcheck-client.json
cat kube-etcd-healthcheck-client.json | jq -r .data.certificate > kube-etcd-healthcheck-client-cert.pem
cat kube-etcd-healthcheck-client.json | jq -r .data.issuing_ca > kube-etcd-healthcheck-client.pem
cat kube-etcd-healthcheck-client.json | jq -r .data.private_key > kube-etcd-healthcheck-client-key.pem
rm kube-etcd-healthcheck-client.json

# kube-apiserver
vault write -format=json kubernetes_int/issue/kubernetes-ca common_name="kubernetes-ca" ttl="24h" ip_sans="127.0.0.1,172.16.16.111" alt_names="localhost,kjump1" > kubernetes-ca.json
cat kubernetes-ca.json | jq -r .data.certificate > kubernetes-ca-cert.pem
cat kubernetes-ca.json | jq -r .data.issuing_ca > kubernetes-ca.pem
cat kubernetes-ca.json | jq -r .data.private_key > kubernetes-ca-key.pem
rm kubernetes-ca.json

#kube-apiserver-kubelet-client
vault write -format=json kubernetes_int/issue/kube-apiserver-kubelet-client common_name="kube-apiserver-kubelet-client" ttl="24h" ip_sans="127.0.0.1,172.16.16.111" alt_names="localhost,kjump1" > kubernetes-ca.json
cat kubernetes-ca.json | jq -r .data.certificate > kubernetes-ca-cert.pem
cat kubernetes-ca.json | jq -r .data.issuing_ca > kubernetes-ca.pem
cat kubernetes-ca.json | jq -r .data.private_key > kubernetes-ca-key.pem
rm kubernetes-ca.json
