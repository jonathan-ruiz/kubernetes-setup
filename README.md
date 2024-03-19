# Kubernetes Installation and Configuration Scripts

This repository contains shell scripts for installing and configuring Kubernetes on Ubuntu-based systems. These scripts are designed to automate the setup process and provide error handling for a smoother installation experience.

## Scripts

### 1. `install_kubernetes_base.sh`

This script installs the base components of Kubernetes, including kubelet, kubeadm, and kubectl. It disables swap, sets up hostname, IPv4 bridge, and sysctl parameters required by Kubernetes. Additionally, it installs Docker and configures containerd.

#### Usage:

```bash
./install_kubernetes_base.sh [-v <version>] [-c <cidr>]
```

##### Options:

- `-v <version>`: Specify the Kubernetes version to install (default: 1.29).
- `-c <cidr>`: Specify the CIDR block for the Kubernetes pod network (default: 192.168.60.0/24).

### 2. `initialize_kubernetes.sh`

This script initializes Kubernetes by pulling necessary images, initializing the cluster, configuring kubeconfig, and displaying the join command.

#### Usage:

```bash
./initialize_kubernetes.sh [-c <cidr>]
```

##### Options:

- `-c <cidr>`: Specify the CIDR block for the Kubernetes pod network (default: 192.168.60.0/24).

### 3. `configure_calico.sh`

This script configures Calico for Kubernetes by creating the necessary resources using kubectl.

#### Usage:

```bash
./configure_calico.sh [-v <version>] [-c <cidr>]
```

##### Options:

- `-v <version>`: Specify the version of Calico to use (default: 3.26.1).
- `-c <cidr>`: Specify the CIDR block for the Calico pod network (default: 192.168.60.0/24).

## Dependencies

- Ubuntu-based Linux distribution (tested on Ubuntu)
- `kubectl` must be installed and configured
- Internet access is required for downloading Kubernetes and Calico resources

## Usage

1. Clone this repository:

```bash
git clone <repository_url>
cd kubernetes-scripts
```

2. Execute the desired script(s) with appropriate options.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

