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

#CA Mount
vault secrets enable -path=kubernetes_root pki

vault secrets tune -max-lease-ttl=87600h kubernetes_root

# Kubernetes CA Cert
vault write -format=json kubernetes_root/root/generate/exported common_name="kubernetes-ca" ttl=315360000s > ca.json

vault write pki/config/urls issuing_certificates="http://desktop-khfd9va.lan:8200/v1/pki/ca" crl_distribution_points="http://desktop-khfd9va.lan:8200/v1/pki/crl"


# Kubernetes Intermediate CA
vault secrets enable -path=kubernetes_int pki

vault secrets tune -max-lease-ttl=43800h kubernetes_int

 vault write -format=json kubernetes_int/intermediate/generate/internal \
        common_name="kubernetes-ca" \
        | jq -r '.data.csr' > pki_intermediate.csr

 vault write -format=json kubernetes_root/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > intermediate.cert.pem

vault write kubernetes_int/intermediate/set-signed certificate=@intermediate.cert.pem

#Roles kubernetes-ca
vault write pki_int/roles/kubernetes-ca \
        allow_bare_domains = true \
        allow_subdomains = true \
        allow_glob_domains = true \
        allow_any_name     = true \
        allow_ip_sans      = true \
        server_flag        = true \
        client_flag        = true \
        max_ttl="720h" \
        ttl     = "730h" \
        key_usage = ["DigitalSignature", "KeyAgreement", "KeyEncipherment","KeyUsageCertSign"] \



#Roles kube-apiserver-kubelet-client
vault write pki_int/roles/kube-apiserver-kubelet-client \
        allow_bare_domains = true \
        allow_subdomains = true \
        allow_glob_domains = true \
        allow_any_name     = true \
        allow_ip_sans      = true \
        server_flag        = true \
        client_flag        = true \
        max_ttl="720h" \
        ttl     = "730h" \
        key_usage = ["DigitalSignature", "KeyAgreement", "KeyEncipherment","KeyUsageCertSign"] \
        organization       = ["system:masters"]




