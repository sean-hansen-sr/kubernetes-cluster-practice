# **System Preparation - All Nodes**
**Disable swap immediately and permanently**  
sudo swapoff -a  
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab  

**Load required kernel modules**  
sudo modprobe overlay  
sudo modprobe br_netfilter  

**Set system networking parameters**  
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf  
net.bridge.bridge-nf-call-iptables  = 1  
net.bridge.bridge-nf-call-ip6tables = 1  
net.ipv4.ip_forward                 = 1  
EOF  

**Apply sysctl settings without rebooting**
sudo sysctl --system  

# **Install Container Runtime - All Nodes**
sudo apt update  
sudo apt install -y containerd  

**Configure containerd to use systemd cgroup**  
sudo mkdir -p /etc/containerd  
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null  
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml  

**Restart containerd to apply changes**  
sudo systemctl restart containerd  
sudo systemctl enable containerd  

# **Install Kubernetes Tools - All Nodes**
**Install package prerequisites**  
sudo apt install -y apt-transport-https ca-certificates curl gpg  

**Download the public signing key for the Kubernetes package repositories**  
**Note: Adjust the version (v1.31, v1.32, etc.) depending on your target version**  
K8S_VERSION=v1.37  
sudo mkdir -p /etc/apt/keyrings  
curl -fsSL https://k8s.io{K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg  

**Add the repository to your system sources**  
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://k8s.io{K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list  

**Install the components**  
sudo apt update  
sudo apt install -y kubelet kubeadm kubectl  

**Pin the versions so apt upgrade doesn't break your cluster**  
sudo apt-mark hold kubelet kubeadm kubectl  

# **Initialize the Control Plane - Control Plane Only**
sudo kubeadm init --pod-network-cidr=10.244.0.0/16  
**Save the kubeadm join command printed when command completes**  

# **Configure kubectl Access - Control Plane Only**
mkdir -p $HOME/.kube  
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config  
sudo chown $(id -u):$(id -g) $HOME/.kube/config  

# **Deploy a Pod Network Plugin - Control Plane Only**
**Install the Calico Custom Resource Definitions**  
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/v1_crd_projectcalico_org.yaml  

**Install the Tigera Operator**  
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/tigera-operator.yaml  

curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/custom-resources.yaml  
**Open the custom-resources.yaml file in a text editor and locate the ipPools section. Crucial: Change the cidr block value (192.168.0.0/16 by default) to match the Pod Network CIDR you specified when initializing your cluster (e.g., if you used kubeadm init --pod-network-cidr=10.244.0.0/16, update the CIDR here to 10.244.0.0/16).**  

kubectl create -f custom-resources.yaml  

kubectl get pods -n calico-system -w  
**Once all pods transition to a Running status, verify that your cluster nodes have recognized the CNI and switched to a healthy state**  

kubectl get nodes  
**The output should now show Ready for all available nodes.**  

# **Join Worker Nodes - Worker Nodes Only**
kubeadm join command saved earlier
