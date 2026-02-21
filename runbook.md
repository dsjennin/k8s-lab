# Kubernetes Lab Runbook
Proxmox + Ubuntu 22.04 + kubeadm + containerd + Flannel  
Single Control Plane Architecture

---

## Cluster Architecture

| Node | Role | IP |
|------|------|----|
| k8s-cp1 | Control Plane | 192.168.1.21 |
| k8s-worker1 | Worker | 192.168.1.22 |
| k8s-worker2 | Worker | 192.168.1.23 |

Ubuntu 22.04 LTS  
User: dave (sudo)

---

# 0. Quick sanity checks (ALL 3 NODES)

SSH into each node and run:

```bash
hostname
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
sudo apt update

```

---

# 1. Base Node Preparation (ALL 3 NODES)

## Disable Swap

```bash
sudo swapoff -a
sudo sed -i '/\\sswap\\s/s/^/#/' /etc/fstab
```

Verify:

```bash
swapon --show
```

---

## Load Kernel Modules

```bash
sudo tee /etc/modules-load.d/k8s.conf >/dev/null <<'EOF'
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

---

## Configure Sysctl Settings

```bash
sudo tee /etc/sysctl.d/k8s.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

---

# 2. Install Container Runtime (ALL 3 NODES)

```bash
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
```

Enable systemd cgroup:

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

Restart and enable:

```bash
sudo systemctl enable --now containerd
sudo systemctl restart containerd
sudo systemctl status containerd --no-pager
```

---

# 3. Install Kubernetes Packages (ALL 3 NODES)

```bash
sudo apt install -y ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings

sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null <<'EOF'
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /
EOF

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Verify:

```bash
kubeadm version
kubectl version --client
```

---

# 4. Initialize Control Plane (ONLY ON k8s-cp1)

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Copy the join command printed at the end.

---

## Configure kubectl (cp1 only)

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config
```

Check:

```bash
kubectl get nodes
```

---

# 5. Install Flannel CNI (cp1 only)

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Wait ~60 seconds:

```bash
kubectl get nodes
```

---

# 6. Join Worker Nodes

On each worker:

```bash
sudo kubeadm join <cp1-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

If needed, regenerate join command on cp1:

```bash
sudo kubeadm token create --print-join-command
```

Verify cluster:

```bash
kubectl get nodes -o wide
```

---

# 7. Test Cluster

```bash
kubectl run hello --image=nginx --restart=Never
kubectl get pods -o wide
kubectl delete pod hello
```

---

# DONE

Cluster operational.
"""