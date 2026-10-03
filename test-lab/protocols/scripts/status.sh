#!/bin/sh
set -eu

lab_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$lab_root"
docker compose ps
