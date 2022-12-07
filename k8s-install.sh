#!/bin/sh

echo "
==================
step1. swap disable
================== "

swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab

sleep 1

echo "STEP1. done"

echo "
==================
step2. Letting iptables see bridge traffic
================== "


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sleep 1

sudo sysctl --system


sleep 1

echo "STEP2. done"

echo "
==================
step3.  Disable firewall
================== "
sudo ufw disable

sleep 1

echo "STEP3. done"

echo "
==================
step4.  Installing Runtime
================== "
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sleep 1

sudo sysctl --system
sleep 1

echo "STEP4. done"

echo "
==================
step5.  Install containerd
================== "

sudo apt-get update

sleep 5

sudo -y apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sleep 10

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sleep 1

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sleep 1

sudo apt-get update
sleep 10

sudo apt-get -y install containerd.io
sleep 10

echo "STEP5. done"

echo "
==================
step6. containerd config
================== "
sudo mkdir -p /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sleep 1

sudo systemctl restart containerd

sleep 3

echo "STEP6. done"

echo "
==================
step7.  Installing kubeadm, kubelet and kubectl
================== "

sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sleep 2
sudo apt-get install -y kubelet kubeadm kubectl
sleep 2
sudo apt-mark hold kubelet kubeadm kubectl

systemctl daemon-reload
systemctl restart kubelet

sleep 2

echo "
_          _                    _
| | ___   _| |__   ___  __ _  __| |_ __ ___
| |/ / | | | '_ \ / _ \/ _` |/ _` | '_ ` _ \
|   <| |_| | |_) |  __/ (_| | (_| | | | | | |
|_|\_\\__,_|_.__/ \___|\__,_|\__,_|_| |_| |_|
"

echo "STEP7. done"
echo "NOW WE ARE READY TO INSTALL KUBEADM"
echo "If this is master node write 'kubeadm init'"
echo "If this is worker node write kubeadm join {token}"
