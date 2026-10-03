#!/bin/sh
set -eu

lab_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
media_dir="$lab_root/data/media"
secret_dir=${SFTP_SECRET_DIR:-/var/lib/linkora-protocol-lab/secrets}
nfs_data_dir=${NFS_DATA_DIR:-/var/lib/linkora-protocol-lab/media}

mkdir -p "$media_dir" "$secret_dir" "$nfs_data_dir"

if [ ! -s "$media_dir/sample-h264.mp4" ]; then
  curl -fL --retry 3 --connect-timeout 15 \
    "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4" \
    -o "$media_dir/sample-h264.mp4.part"
  mv "$media_dir/sample-h264.mp4.part" "$media_dir/sample-h264.mp4"
fi

mkdir -p "$media_dir/Movies/Action" "$media_dir/Movies/Animation" \
  "$media_dir/Series/Season 01" "$media_dir/Clips"
cp "$media_dir/sample-h264.mp4" "$media_dir/Movies/Action/City Chase 1080P.mp4"
cp "$media_dir/sample-h264.mp4" "$media_dir/Movies/Animation/Big Buck Bunny.mp4"
cp "$media_dir/sample-h264.mp4" "$media_dir/Series/Season 01/Episode 01 - Pilot.mp4"
cp "$media_dir/sample-h264.mp4" "$media_dir/Series/Season 01/Episode 02 - Test.mp4"
cp "$media_dir/sample-h264.mp4" "$media_dir/Clips/Network Sample.mp4"

cp -R "$media_dir/." "$nfs_data_dir/"
find "$nfs_data_dir" -type f -exec chmod 644 {} \;

if [ ! -s "$secret_dir/sftp_client_ed25519" ]; then
  ssh-keygen -q -t ed25519 -N '' -C 'linkora-protocol-lab-client' \
    -f "$secret_dir/sftp_client_ed25519"
fi

if [ ! -s "$secret_dir/ssh_host_ed25519_key" ]; then
  ssh-keygen -q -t ed25519 -N '' -C 'linkora-protocol-lab-host' \
    -f "$secret_dir/ssh_host_ed25519_key"
fi

chmod 600 "$secret_dir/sftp_client_ed25519" "$secret_dir/ssh_host_ed25519_key"
chmod 644 "$secret_dir/sftp_client_ed25519.pub" "$secret_dir/ssh_host_ed25519_key.pub"

printf 'Protocol lab assets are ready in %s\n' "$lab_root"
printf 'SFTP test keys are ready in %s\n' "$secret_dir"
