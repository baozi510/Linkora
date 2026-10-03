#!/bin/sh
set -eu

lab_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
host_ip=${LAB_HOST_IP:-$(hostname -I | awk '{print $1}')}
key_dir=${SFTP_SECRET_DIR:-/var/lib/linkora-protocol-lab/secrets}
samba_image='dockurr/samba@sha256:404f91bdf317d390241a41165579cd25199f34171b44677d877c75dc40184042'

cd "$lab_root"

auth_missing=$(curl -sS -o /dev/null -w '%{http_code}' -X PROPFIND -H 'Depth: 1' \
  http://127.0.0.1:19080/)
test "$auth_missing" = '401'

auth_status=$(curl -sS -u 'linkora:LinkoraTest123!' -o /tmp/linkora-webdav-auth.xml \
  -w '%{http_code}' -X PROPFIND -H 'Depth: 1' http://127.0.0.1:19080/)
test "$auth_status" = '207'
grep -q 'sample-h264.mp4' /tmp/linkora-webdav-auth.xml

guest_status=$(curl -sS -o /tmp/linkora-webdav-guest.xml -w '%{http_code}' \
  -X PROPFIND -H 'Depth: 1' http://127.0.0.1:19081/)
test "$guest_status" = '207'
grep -q 'sample-h264.mp4' /tmp/linkora-webdav-guest.xml

range_status=$(curl -sS -u 'linkora:LinkoraTest123!' -o /tmp/linkora-webdav-range.bin \
  -w '%{http_code}' -H 'Range: bytes=0-1023' http://127.0.0.1:19080/sample-h264.mp4)
test "$range_status" = '206'
test "$(wc -c < /tmp/linkora-webdav-range.bin)" = '1024'
printf 'PASS WebDAV auth, guest, 401 and Range\n'

docker run --rm --network host --entrypoint /usr/bin/smbclient "$samba_image" \
  //127.0.0.1/Media -p 1445 -U 'linkora%LinkoraTest123!' -c ls 2>/dev/null | grep -q sample-h264.mp4
docker run --rm --network host --entrypoint /usr/bin/smbclient "$samba_image" \
  //127.0.0.1/GuestMedia -p 1446 -N -c ls 2>/dev/null | grep -q sample-h264.mp4
if docker run --rm --network host --entrypoint /usr/bin/smbclient "$samba_image" \
  //127.0.0.1/Media -p 1445 -U 'linkora%wrong-password' -c ls >/dev/null 2>&1; then
  echo 'SMB accepted an invalid password.' >&2
  exit 1
fi
printf 'PASS SMB password, guest and invalid password\n'

scan_key=$(ssh-keyscan -p 12223 -t ed25519 127.0.0.1 2>/dev/null | awk '{print $2, $3}')
expected_key=$(ssh-keygen -y -f "$key_dir/ssh_host_ed25519_key" | awk '{print $1, $2}')
test "$scan_key" = "$expected_key"
printf 'ls media\nquit\n' | timeout 12 sftp -q -P 12223 \
  -i "$key_dir/sftp_client_ed25519" -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null linkora@127.0.0.1 \
  > /tmp/linkora-sftp-key.txt
grep -q sample-h264.mp4 /tmp/linkora-sftp-key.txt

docker run --rm --network host alpine:3.22 sh -lc \
  "apk add --no-cache openssh-client sshpass >/dev/null 2>&1; \
  printf 'ls media\\nquit\\n' | sshpass -p 'LinkoraTest123!' sftp -q -P 12222 \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null linkora@127.0.0.1" \
  | grep -q sample-h264.mp4
printf 'PASS SFTP password, key and host fingerprint\n'

curl -sS --user 'linkora:LinkoraTest123!' --list-only "ftp://$host_ip:12121/" \
  | grep -q sample-h264.mp4
curl -sS --user 'anonymous:' --list-only "ftp://$host_ip:12122/" \
  | grep -q sample-h264.mp4
if curl -sS --user 'linkora:wrong-password' --list-only "ftp://$host_ip:12121/" >/dev/null 2>&1; then
  echo 'FTP accepted an invalid password.' >&2
  exit 1
fi
printf 'PASS FTP password, anonymous and invalid password\n'

docker run --rm --privileged --network host alpine:3.22 sh -lc \
  "apk add --no-cache nfs-utils >/dev/null 2>&1; mkdir -p /mnt/lab; \
  mount -t nfs4 -o vers=4,port=12049 127.0.0.1:/ /mnt/lab; \
  test -s /mnt/lab/sample-h264.mp4; \
  if touch /mnt/lab/write-should-fail 2>/dev/null; then umount /mnt/lab; exit 2; fi; \
  umount /mnt/lab"
printf 'PASS NFS v4 read-only export\n'

printf 'All Linkora protocol lab checks passed. Host IP: %s\n' "$host_ip"
