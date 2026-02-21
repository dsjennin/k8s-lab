SHELL := /bin/bash

INVENTORY := ansible/inventory.ini
PLAYBOOK  := ansible/k8s_prereqs.yml

.PHONY: help ansible-prereqs ping ssh-cp1 ssh-w1 ssh-w2

help:
	@echo "Targets:"
	@echo "  make ansible-prereqs   # Prep all nodes (swap/modules/sysctl/containerd/kube tools)"
	@echo "  make ping              # Ping all nodes"
	@echo "  make ssh-cp1           # SSH to control plane"
	@echo "  make ssh-w1            # SSH to worker1"
	@echo "  make ssh-w2            # SSH to worker2"

ansible-prereqs:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

ping:
	./scripts/ping-nodes.sh

ssh-cp1:
	./scripts/ssh-into.sh 192.168.1.21

ssh-w1:
	./scripts/ssh-into.sh 192.168.1.22

ssh-w2:
	./scripts/ssh-into.sh 192.168.1.23