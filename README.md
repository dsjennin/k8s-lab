# k8s-lab
# k8s-lab

Kubernetes lab environment on Proxmox using Ubuntu 22.04 VMs, `kubeadm`, `containerd`, and Flannel.

## Topology (single control plane)

| Node | Role | IP |
|---|---|---|
| k8s-cp1 | Control Plane | 192.168.1.21 |
| k8s-worker1 | Worker | 192.168.1.22 |
| k8s-worker2 | Worker | 192.168.1.23 |

User: `dave` (sudo)

## How to use this repo

### Option A — Manual (recommended first time)
Follow `runbook.md`.

### Option B — Ansible (repeatable)
1. Install Ansible on your workstation
2. Update `ansible/inventory.ini` if your IPs/users differ
3. Run:
   - `make ansible-prereqs`

Then return to `runbook.md` to run:
- `kubeadm init` on cp1
- install Flannel
- join workers

## Notes
- This assumes Ubuntu 22.04 on all nodes.
- Proxmox networking uses `vmbr0` bridged to LAN.
- If you rebuild VMs, you may need to clear old SSH host keys:
  `ssh-keygen -R 192.168.1.21` (and similarly for workers)