#!/bin/sh
set -eu

lab_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lab_host_ip=${LAB_HOST_IP:-$(hostname -I | awk '{print $1}')}
nfs_data_dir=${NFS_DATA_DIR:-/var/lib/linkora-protocol-lab/media}
sftp_secret_dir=${SFTP_SECRET_DIR:-/var/lib/linkora-protocol-lab/secrets}

if [ -z "$lab_host_ip" ]; then
  echo 'Unable to determine LAB_HOST_IP.' >&2
  exit 1
fi

export LAB_HOST_IP="$lab_host_ip"
export NFS_DATA_DIR="$nfs_data_dir"
export SFTP_SECRET_DIR="$sftp_secret_dir"
cd "$lab_root"
docker compose up -d --build
printf 'Linkora protocol lab started with LAB_HOST_IP=%s\n' "$LAB_HOST_IP"
