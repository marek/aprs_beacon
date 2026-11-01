#!/usr/bin/env bash
#
# Smoke-test aprs_beacon against fake Pi-Star config files, with --dry-run so
# nothing is sent. Each case checks the exact packet the script would send.
#
# Usage: tools/smoke-test.sh [PACKAGE.deb]
#
# With a .deb, tests the script and default config packaged in it (needs
# dpkg-deb); without one, tests pkg/ in this checkout (any bash >= 4.2).

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if (( $# )); then
  dpkg-deb -x "$1" "$work/staged"
  tree=$work/staged
else
  tree=$root/pkg
fi
beacon=$tree/usr/bin/aprs_beacon

cd "$work"

# a do-nothing logger first on PATH, so the error cases don't write to the
# system log of whatever machine runs the test
mkdir bin
printf '#!/bin/sh\nexit 0\n' > bin/logger
chmod +x bin/logger
PATH=$work/bin:$PATH

printf '[General]\nCallsign=N0CALL\n[APRS-IS]\nServer=127.0.0.1\nPort=14580\n' > aprsgateway
printf '[General]\nDuplex=1\n[Info]\nLatitude=43.8509\nLongitude=-79.0204\n' > duplex
printf '[General]\nDuplex=0\n[Info]\nLatitude=-33.8688\nLongitude=151.2093\n' > simplex
printf '[Info]\nLatitude=95\nLongitude=0\n' > badlat
printf 'Raspberry Pi 3 Model B Plus Rev 1.3\0' > model_3bp
printf 'Raspberry Pi Zero 2 W Rev 1.0\0' > model_zero
mkdir mmdvm dstar none
printf '[Modem]\nHardware=mmdvmhsdualhatgpio\n' > mmdvm/dstar-radio.mmdvmhost
printf '[Modem]\nHardware=dvap\n' > dstar/dstar-radio.dstarrepeater
# lines as the Pi-Star dashboard's Radio/Modem Type list has them
cat > configure.php <<'EOF'
        <option<?php if (isset($configModem['Modem']['Hardware']) && $configModem['Modem']['Hardware'] === 'dvap') {        echo ' selected="selected"';}?> value="dvap">DVAP (USB)</option>
        <option<?php if (isset($configModem['Modem']['Hardware']) && $configModem['Modem']['Hardware'] === 'mmdvmhsdualhatgpio') {        echo ' selected="selected"';}?> value="mmdvmhsdualhatgpio">MMDVM_HS_Duplex_Hat (DB9MAT, DF2ET &amp; DO7EN) for Pi (GPIO)</option>
EOF

failed=0

# check NAME EXPECTED_OUTPUT [VAR=value...] - run a dry run with the default
# fixtures, overridden by the VAR=value pairs, and compare its output
check()
{
  local name=$1 expected=$2 out
  shift 2
  out=$(env CONFIG_APRS=aprsgateway CONFIG_MMDVM=duplex DEVICE_MODEL=model_3bp \
            DSTAR_RADIO=mmdvm/dstar-radio DASHBOARD_CONFIG=configure.php \
            CONFIG_BEACON="$tree/etc/aprs_beacon" "$@" \
            "$BASH" "$beacon" --dry-run 2>&1) || true
  if [[ $out == "$expected" ]]; then
    echo "ok    $name"
  else
    echo "FAIL  $name"
    echo "      expected: $expected"
    echo "      got:      $out"
    failed=1
  fi
}

check "duplex MMDVMHost, Pi 3 B+, hat modem" \
  'would send N0CALL-1>APRS,TCPIP*:!4351.05N/07901.22W1MMDVMHost Duplex Hotspot, RPi 3 Model B Plus, MMDVM_HS_Duplex_Hat'

check "simplex DStarRepeater, Pi Zero 2 W, south/east position" \
  'would send N0CALL-1>APRS,TCPIP*:!3352.13S/15112.56E1DStarRepeater Simplex Hotspot, RPi Zero 2 W, DVAP' \
  CONFIG_MMDVM=simplex DEVICE_MODEL=model_zero DSTAR_RADIO=dstar/dstar-radio

check "no dashboard: raw modem key" \
  'would send N0CALL-1>APRS,TCPIP*:!4351.05N/07901.22W1MMDVMHost Duplex Hotspot, RPi 3 Model B Plus, mmdvmhsdualhatgpio' \
  DASHBOARD_CONFIG=missing

check "no controller marker or board model" \
  'would send N0CALL-1>APRS,TCPIP*:!4351.05N/07901.22W1unknown Duplex Hotspot, unknown, unknown' \
  DSTAR_RADIO=none/dstar-radio DEVICE_MODEL=missing

check "latitude out of range is refused" \
  "error: invalid latitude '95'" \
  CONFIG_MMDVM=badlat

exit $failed
