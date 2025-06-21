# Radxa-ROCK5BP-25W-POE-FAN

This repository provides scripts and device-tree files to enable and control
the 25 W PoE+ HAT fan on the Radxa ROCK5 board.

## Prerequisites
- Debian or similar Linux distribution
- `dtc` (device-tree compiler) for building the overlay
- Root privileges for installing files under `/usr/local`, `/etc` and `/lib/firmware`

## Installation
1. Clone this repository on the target system.
2. Run the installer as root:
   ```bash
   sudo ./scripts/install.sh
   ```
   This will compile the device-tree overlay, install the fan control service
   and enable it so it starts automatically on boot.

## Configuration
Fan behaviour can be customised by editing `/etc/default/radxa-poe-fan` after
installation. Temperature thresholds and corresponding PWM values are defined
as Bash arrays:
```bash
TEMP_THRESHOLDS=(60 65 70 75)
PWM_VALUES=(0 64 128 192 255)
```
Set `VERBOSE=1` to print status messages to the console.

The control script attempts to locate the PWM fan device automatically by
scanning `/sys/class/hwmon/`. If this fails, it falls back to `hwmon10`.

## Uninstallation
To remove the service and overlay, disable and delete the installed files:
```bash
sudo systemctl disable --now radxa-poe-fan.service
sudo rm /etc/systemd/system/radxa-poe-fan.service
sudo rm /usr/local/bin/radxa-poe-fancontrol.sh
sudo rm /etc/default/radxa-poe-fan
sudo rm /lib/firmware/rockchip/overlay/rock-5b-radxa-25w-poe.dtbo
```
