# APRS Beacon

A command-line script for making [pi-star](https://www.pistar.uk) hotspots visible on the [aprs.fi](http://aprs.fi) map

While MMDVMHost can be configured to forward APRS positional messages with no issue; when configured strictly for the DMR network the hotspot has no beacon capability.

## Installation <a id="installation"></a>

Make sure your pistar hotspot has a callsign, latitude and longitude configured. Keep in mind that this script does not do reduce the accuracy of the coordinates. If you value your privacy omit a few decimal places.
<img width="822" alt="general_configuration" src="https://github.com/user-attachments/assets/c8569b00-630c-46f9-bba7-af0b07f3d98b">

To download and install:

```shell
cd /tmp
wget -O aprs_beacon.tgz https://github.com/marek/aprs_beacon/releases/latest/download/aprs_beacon.tgz

# make pistar filesystem writeable
rpi-rw

# download and extract to root
sudo tar -vxzf aprs_beacon.tgz -C /
sudo chown mmdvm:mmdvm /home/mmdvm/aprs_beacon

# edit SSID suffix, APRS symbol and description
sudo nano /etc/aprs_beacon
rpi-ro
```


## Additional configuration <a id="configuration"></a>

By default APRS Beacon is configured to update every 5 minutes.
To change this edit the cronfile `/etc/cron.d/aprs_beacon` to your liking.

```bash
rpi-rw
sudo nano /etc/cron.d/aprs_beacon
rpi-ro
```