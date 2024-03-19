#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-v <version>] [-c <cidr>]" 1>&2;
    exit 1;
}

# Default values
VERSION="3.26.1"
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

# Configure kubectl and calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v$VERSION/manifests/tigera-operator.yaml || { echo "Error: Unable to create tigera-operator." >&2; exit 1; }
curl -o custom-resources.yaml https://raw.githubusercontent.com/projectcalico/calico/v$VERSION/manifests/custom-resources.yaml || { echo "Error: Unable to download custom-resources.yaml." >&2; exit 1; }
sed -i "s/cidr: 192\.168\.0\.0\/16/cidr: $CIDR/g" custom-resources.yaml || { echo "Error: Unable to modify custom-resources.yaml." >&2; exit 1; }
kubectl create -f custom-resources.yaml || { echo "Error: Unable to create custom resources." >&2; exit 1; }

echo "Calico configuration completed successfully."

