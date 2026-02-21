# Proxmox Setup Guide

Homelab Kubernetes Environment Foundation

This document covers:

-   Proxmox installation basics
-   Network configuration
-   Creating Ubuntu cloud-init template
-   Cloning Kubernetes VMs
-   Recommended VM sizing

------------------------------------------------------------------------

# 1. Install Proxmox VE

## Download ISO

Download the latest Proxmox VE ISO from:
https://www.proxmox.com/en/downloads

## Installation Steps

1.  Boot from ISO
2.  Select **Install Proxmox VE**
3.  Choose target disk
4.  Set:
    -   Hostname (example: pve-1.local)
    -   Static IP (example: 192.168.1.10)
    -   Gateway (example: 192.168.1.1)
5.  Complete install and reboot

Access Web UI:

    https://<proxmox-ip>:8006

------------------------------------------------------------------------

# 2. Network Configuration

Default setup creates:

-   `vmbr0` (Linux Bridge)
-   Bound to physical NIC
-   Used for VM networking

Verify under:

Datacenter → Node → Network

Ensure: - vmbr0 is active - IPv4 static IP configured - Gateway set
correctly

------------------------------------------------------------------------

# 3. Storage Configuration

Typical default:

-   local (ISO + backups)
-   local-lvm (VM disks)

Recommended: - Use local-lvm for VM disks - Ensure sufficient space (\>=
200GB recommended)

------------------------------------------------------------------------

# 4. Create Ubuntu Cloud-Init Template

## Download Ubuntu 22.04 Cloud Image

On Proxmox node:

``` bash
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

------------------------------------------------------------------------

## Create VM Template

Example (VM ID 9000):

``` bash
qm create 9000 --name ubuntu-template --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
```

Resize disk:

``` bash
qm resize 9000 scsi0 40G
```

Convert to template:

``` bash
qm template 9000
```

------------------------------------------------------------------------

# 5. Clone Kubernetes Nodes

Example:

``` bash
qm clone 9000 101 --name k8s-cp1 --full
qm clone 9000 102 --name k8s-worker1 --full
qm clone 9000 103 --name k8s-worker2 --full
```

Set static IPs:

``` bash
qm set 101 --ipconfig0 ip=192.168.1.21/24,gw=192.168.1.1
qm set 102 --ipconfig0 ip=192.168.1.22/24,gw=192.168.1.1
qm set 103 --ipconfig0 ip=192.168.1.23/24,gw=192.168.1.1
```

Start VMs:

``` bash
qm start 101
qm start 102
qm start 103
```

------------------------------------------------------------------------

# 6. Recommended VM Sizing

Control Plane: - 4 vCPU - 8GB RAM - 40GB disk

Workers: - 2--4 vCPU - 4--8GB RAM - 40GB disk

------------------------------------------------------------------------

# 7. Optional Improvements

-   Enable Proxmox Backup
-   Configure VLAN-aware bridges
-   Separate storage disk for VMs
-   Use SSD/NVMe for best performance

------------------------------------------------------------------------

# DONE

Proxmox is ready for Kubernetes deployment.
