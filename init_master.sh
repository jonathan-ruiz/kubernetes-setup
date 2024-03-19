#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-c <cidr>]" 1>&2;
    exit 1;
}

# Default values
CIDR=hostname -I | awk '{print $1}' | awk -F'.' '{print $1"."$2"."$3".0/24"}'

# Parse command line options
while getopts ":c:" opt; do
    case ${opt} in
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

# Pull Kubernetes images
sudo kubeadm config images pull || { echo "Error: Unable to pull Kubernetes images." >&2; exit 1; }

# Initialize Kubernetes
sudo kubeadm init --pod-network-cidr=$CIDR --control-plane-endpoint $(hostname -I | awk '{print $1}') || { echo "Error: Unable to initialize Kubernetes cluster." >&2; exit 1; }

# Configure kubeconfig
mkdir -p $HOME/.kube || { echo "Error: Unable to create directory $HOME/.kube." >&2; exit 1; }
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config || { echo "Error: Unable to copy admin.conf to $HOME/.kube/config." >&2; exit 1; }
sudo chown $(id -u):$(id -g) $HOME/.kube/config || { echo "Error: Unable to change ownership of $HOME/.kube/config." >&2; exit 1; }

# Show join command
kubeadm token create --print-join-command || { echo "Error: Unable to generate join command." >&2; exit 1; }

echo "Kubernetes initialization completed successfully."

