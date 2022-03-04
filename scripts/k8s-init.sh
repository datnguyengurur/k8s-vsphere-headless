#!/bin/bash
DEBIAN_FRONTEND=noninteractive
sudo swapoff -a;
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab;

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg;
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update;

DEBIAN_FRONTEND=noninteractive sudo apt install -y containerd apt-transport-https ca-certificates nfs-common open-iscsi kubelet kubeadm kubectl;
sudo apt-mark hold kubelet kubeadm kubectl;
DEBIAN_FRONTEND=noninteractive sudo apt upgrade -y;
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo growpart /dev/sda 3;
sudo pvresize /dev/sda3;
sudo lvextend --extents +100%FREE /dev/mapper/sysvg-root;
sudo xfs_growfs /dev/mapper/sysvg-root