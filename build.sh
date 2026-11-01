#!/bin/bash
#
# Build dist/aprs-beacon_<version>_all.deb from pkg/. Needs dpkg-deb (Debian,
# Ubuntu or the Pi itself); the version comes from the VERSION file.

set -euo pipefail
cd "$(dirname "$0")"

version=$(tr -d '[:space:]' < VERSION)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

cp -R pkg/. "$stage/"
sed -i "s/^Version:.*/Version: $version/" "$stage/DEBIAN/control"
sed -i "s/^VERSION=.*/VERSION=$version/" "$stage/usr/bin/aprs_beacon"

find "$stage" -type d -exec chmod 0755 {} +
find "$stage" -type f -exec chmod 0644 {} +
chmod 0755 "$stage/usr/bin/aprs_beacon" "$stage/DEBIAN/preinst"

# xz, not the zstd newer Ubuntu dpkg defaults to: Pi-Star's dpkg 1.20 (bullseye)
# can't unpack zstd
mkdir -p dist
dpkg-deb -Zxz --root-owner-group --build "$stage" "dist/aprs-beacon_${version}_all.deb"
