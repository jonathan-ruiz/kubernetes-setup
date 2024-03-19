#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-v <version>] [-c <cidr>]" 1>&2;
    exit 1;
}

# Default values
VERSION="1.29"
CIDR=hostname -I | awk '{print $1}' | awk -F'.' '{print $1"."$2"."$3".0/24"}'

# Parse command line options
while getopts ":v:c:" opt; do
    case ${opt} in
        v )
            VERSION=$OPTARG
            ;;
        c )
            CIDR=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Disable Swap
sudo swapoff -a || { echo "Error: Unable to disable swap." >&2; exit 1; }
sudo sed -i '/ swap / s/^/#/' /etc/fstab || { echo "Error: Unable to update /etc/fstab." >&2; exit 1; }

# Set up hostname 
sudo hostnamectl set-hostname "master" || { echo "Error: Unable to set hostname." >&2; exit 1; }

# Set up ipv4 bridge
sudo tee /etc/modules-load.d/k8s.conf <<EOF || { echo "Error: Unable to write to k8s.conf." >&2; exit 1; }
overlay
br_netfilter
EOF

sudo modprobe overlay || { echo "Error: Unable to load overlay kernel module." >&2; exit 1; }
sudo modprobe br_netfilter || { echo "Error: Unable to load br_netfilter kernel module." >&2; exit 1; }

# sysctl params required by setup, params persist across reboots
sudo tee /etc/sysctl.d/k8s.conf <<EOF || { echo "Error: Unable to write to sysctl.d/k8s.conf." >&2; exit 1; }
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system || { echo "Error: Unable to apply sysctl params." >&2; exit 1; }

# Install kubelet, kubeadm & kubectl
sudo apt update || { echo "Error: Unable to update apt repository." >&2; exit 1; }
sudo apt install -y apt-transport-https ca-certificates curl || { echo "Error: Unable to install required packages." >&2; exit 1; }
sudo mkdir -p /etc/apt/keyrings || { echo "Error: Unable to create directory /etc/apt/keyrings." >&2; exit 1; }
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list || { echo "Error: Unable to write to kubernetes.list." >&2; exit 1; }
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || { echo "Error: Unable to retrieve GPG key." >&2; exit 1; }
sudo apt update || { echo "Error: Unable to update apt repository." >&2; exit 1; }
sudo apt install -y kubelet=$VERSION* kubeadm=$VERSION* kubectl=$VERSION* || { echo "Error: Unable to install Kubernetes packages." >&2; exit 1; }

# Install docker
sudo apt install -y docker.io || { echo "Error: Unable to install Docker." >&2; exit 1; }
sudo mkdir -p /etc/containerd || { echo "Error: Unable to create directory /etc/containerd." >&2; exit 1; }
sudo sh -c "containerd config default > /etc/containerd/config.toml" || { echo "Error: Unable to configure containerd." >&2; exit 1; }
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml || { echo "Error: Unable to update containerd config." >&2; exit 1; }
sudo systemctl restart containerd.service || { echo "Error: Unable to restart containerd service." >&2; exit 1; }
sudo systemctl restart kubelet.service || { echo "Error: Unable to restart kubelet service." >&2; exit 1; }
sudo systemctl enable kubelet.service || { echo "Error: Unable to enable kubelet service." >&2; exit 1; }

echo "Kubernetes setup completed successfully."

