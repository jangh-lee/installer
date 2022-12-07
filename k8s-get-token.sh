#!/bin/bash

HOST=`hostname -I`
PORT=6443
TOKEN=`kubeadm token create`
HASH=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`

echo "kubeadm join ${HOST}:${PORT} --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${HASH}"
echo "kubeadm join ${HOST}:${PORT} --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${HASH}" >>token.txt
