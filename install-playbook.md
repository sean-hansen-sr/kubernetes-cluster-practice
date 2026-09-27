# **System Preparation - All Nodes**
## Disable swap immediately and permanently
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Set system networking parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl settings without rebooting
sudo sysctl --system

# Install Container Runtime - All Nodes
sudo apt update
sudo apt install -y containerd

# Configure containerd to use systemd cgroup
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd to apply changes
sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kubernetes Tools - All Nodes
# Install package prerequisites
sudo apt install -y apt-transport-https ca-certificates curl gpg

# Download the public signing key for the Kubernetes package repositories
# Note: Adjust the version (v1.31, v1.32, etc.) depending on your target version
K8S_VERSION=v1.31
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://k8s.io{K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the repository to your system sources
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://k8s.io{K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install the components
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Pin the versions so apt upgrade doesn't break your cluster
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize the Control Plane - Control Plane Only
sudo kubeadm init --pod-network-cidr=10.244.0.0/16


