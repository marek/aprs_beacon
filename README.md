# APRS Beacon

A command-line script for making [pi-star](https://www.pistar.uk) hotspots visible on the [aprs.fi](http://aprs.fi) map.

While MMDVMHost can be configured to forward APRS positional messages with no issue; when configured strictly for the DMR network the hotspot has no beacon capability.

<img width="400" alt="aprs fi screenshot" src="https://github.com/user-attachments/assets/4347f113-5dd6-4ab3-ba69-9d2b062ab845">


## Do I need this? <a id="need"></a>

Only if you want your hotspot's location public on aprs.fi. In DMR or P25 mode, nothing else broadcasts it at regular intervals.

Pi-Star's Fusion, NXDN and D-Star gateways do beacon, so if you run one of those you don't need this. Don't enable one just for the beacon: on a simplex hotspot, extra modes compete with DMR.


## Installation <a id="installation"></a>

Make sure your pistar hotspot has a callsign, latitude and longitude configured, and that APRSGateway has an APRS-IS server set. Keep in mind that this script does not reduce the accuracy of the coordinates. If you value your privacy omit a few decimal places, or set `Latitude`/`Longitude` in `/etc/aprs_beacon`.
<img width="822" alt="general_configuration" src="https://github.com/user-attachments/assets/c8569b00-630c-46f9-bba7-af0b07f3d98b">

To download and install:

```shell
cd /tmp
wget -O aprs-beacon.deb https://github.com/marek/aprs_beacon/releases/latest/download/aprs-beacon_all.deb

# make pistar filesystem writeable
rpi-rw

sudo dpkg -i --force-confold aprs-beacon.deb

# edit SSID suffix, APRS symbol and description
sudo nano /etc/aprs_beacon

# make pistar filesystem read-only again
rpi-ro
```

Installing the package replaces a manual install of version 0.1 (`/home/mmdvm/aprs_beacon`). `--force-confold` keeps an existing `/etc/aprs_beacon`.

To remove it: `rpi-rw; sudo dpkg --purge aprs-beacon; rpi-ro`.


## Additional configuration <a id="configuration"></a>

By default APRS Beacon is configured to update every 5 minutes.
To change this edit the cronfile `/etc/cron.d/aprs_beacon` to your liking.

```bash
rpi-rw
sudo nano /etc/cron.d/aprs_beacon
rpi-ro
```

`Description` in `/etc/aprs_beacon` can use placeholders filled in from the hotspot's own settings, so one config fits every hotspot:

| Placeholder | Becomes | From |
|---|---|---|
| `{controller}` | `MMDVMHost` or `DStarRepeater` | Pi-Star's Controller Software marker, `/etc/dstar-radio.*` |
| `{mode}` | `Simplex` or `Duplex` | `Duplex=` in `/etc/mmdvmhost` |
| `{device}` | e.g. `RPi Zero 2 W` | the board model in the device tree |
| `{modem}` | e.g. `STM32-DVM / MMDVM_HS - Raspberry Pi Hat` | the Radio/Modem Type, named as the Pi-Star dashboard lists it |

The default `{controller} {mode} Hotspot, {device}, {modem}` gives `MMDVMHost Simplex Hotspot, RPi Zero 2 W, STM32-DVM / MMDVM_HS - Raspberry Pi Hat`. Comments are capped at 128 characters; the APRS spec's 43-character limit is for RF, and this beacon only goes to APRS-IS.

The beacon logs in to APRS-IS as `CALLSIGN-Suffix`, so it never collides with APRSGateway's own login. If the configured server can't be reached it falls back to `rotate.aprs2.net`.


## Troubleshooting <a id="troubleshooting"></a>

Every run is logged to syslog:

```bash
grep aprs_beacon /var/log/syslog | tail
```

To see what would be sent without sending it, or to send one beacon now:

```bash
sudo -u mmdvm aprs_beacon --dry-run
sudo -u mmdvm aprs_beacon
```

`login ... not verified` means APRS-IS rejected the passcode; check the APRS-IS password in the Pi-Star configuration.


## Building <a id="building"></a>

`./build.sh` builds `dist/aprs-beacon_<version>_all.deb` from `pkg/`, using the version in `VERSION`. It needs `dpkg-deb`, so run it on Debian/Ubuntu or on the hotspot itself.

`tools/smoke-test.sh` dry-runs the beacon against fake Pi-Star config files and checks the exact packets: with no argument it tests `pkg/` in the checkout (any bash 4.2+, macOS included via Homebrew bash), and `tools/smoke-test.sh dist/aprs-beacon_<version>_all.deb` tests the built package.

Pushing a `v*` tag that matches `VERSION` (e.g. `v0.2.0`) builds, smoke-tests and installs the package in Debian bullseye (Pi-Star 4.2's release) and drafts a GitHub release with it; publish the draft to make it the latest download.
