#!/bin/bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "This installer must be run as root" >&2
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Compile device-tree overlay
if [ -x "$SCRIPT_DIR/../overlay/compile-overlay" ]; then
    (cd "$SCRIPT_DIR/../overlay" && ./compile-overlay)
fi

# Copy overlay to firmware directory
install -D -m 644 "$SCRIPT_DIR/../overlay/rock-5b-radxa-25w-poe-fixed.dtbo" \
    /lib/firmware/rockchip/overlay/rock-5b-radxa-25w-poe.dtbo

# Enable overlay in /etc/default/u-boot
U_BOOT_CFG=/etc/default/u-boot
if ! grep -q "rock-5b-radxa-25w-poe.dtbo" "$U_BOOT_CFG"; then
    echo "Updating $U_BOOT_CFG";
    sed -i 's|^U_BOOT_FDT_OVERLAYS=.*|U_BOOT_FDT_OVERLAYS="rockchip/overlay/rock-5b-radxa-25w-poe.dtbo"|' "$U_BOOT_CFG"
fi

# Install service and script
install -D -m 755 "$SCRIPT_DIR/radxa-poe-fancontrol.sh" /usr/local/bin/radxa-poe-fancontrol.sh
install -D -m 644 "$SCRIPT_DIR/../radxa-poe-fan.service" /etc/systemd/system/radxa-poe-fan.service
install -D -m 644 "$SCRIPT_DIR/radxa-poe-fan.conf" /etc/default/radxa-poe-fan

systemctl daemon-reload
systemctl enable radxa-poe-fan.service
systemctl restart radxa-poe-fan.service

echo "Installation complete"
