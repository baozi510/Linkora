#!/bin/sh
set -eu

pasv_address="${PASV_ADDRESS:-127.0.0.1}"
sed "s/__PASV_ADDRESS__/${pasv_address}/" /etc/vsftpd/vsftpd.conf > /tmp/vsftpd.conf
exec /usr/sbin/vsftpd /tmp/vsftpd.conf
