#!/bin/sh
set -eu

host_ip=${LAB_HOST_IP:-$(hostname -I | awk '{print $1}')}
key_dir=${SFTP_SECRET_DIR:-/var/lib/linkora-protocol-lab/secrets}

printf 'Linkora protocol lab host: %s\n\n' "$host_ip"
printf 'WebDAV auth : http://%s:19080/  linkora / LinkoraTest123!\n' "$host_ip"
printf 'WebDAV guest: http://%s:19081/\n' "$host_ip"
printf 'SMB auth    : smb://%s:1445/Media  linkora / LinkoraTest123!\n' "$host_ip"
printf 'SMB guest   : smb://%s:1446/GuestMedia\n' "$host_ip"
printf 'SFTP pass   : sftp://linkora@%s:12222/media/\n' "$host_ip"
printf 'SFTP key    : sftp://linkora@%s:12223/media/\n' "$host_ip"
printf 'FTP auth    : ftp://%s:12121/  linkora / LinkoraTest123!\n' "$host_ip"
printf 'FTP guest   : ftp://%s:12122/  anonymous\n' "$host_ip"
printf 'NFS v4      : %s:/ via TCP port 12049\n' "$host_ip"
printf 'Direct MP4  : http://%s:19081/sample-h264.mp4\n' "$host_ip"

if [ -f "$key_dir/ssh_host_ed25519_key.pub" ]; then
  printf '\nSFTP Ed25519 host fingerprint:\n'
  ssh-keygen -lf "$key_dir/ssh_host_ed25519_key.pub"
fi

