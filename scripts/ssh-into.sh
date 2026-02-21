#!/usr/bin/env bash
set -euo pipefail

IP="${1:-}"
if [[ -z "$IP" ]]; then
  echo "Usage: $0 <ip>"
  exit 1
fi

ssh dave@"$IP"