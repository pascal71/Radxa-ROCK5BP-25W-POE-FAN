#!/bin/bash
set -euo pipefail

CONFIG_FILE=/etc/default/radxa-poe-fan

if [ "${EUID}" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Load configuration if present
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CONFIG_FILE"
fi

if [[ -z ${TEMP_THRESHOLDS+x} ]]; then
    TEMP_THRESHOLDS=(60 65 70 75)
fi
if [[ -z ${PWM_VALUES+x} ]]; then
    PWM_VALUES=(0 64 128 192 255)
fi
: "${VERBOSE:=0}"

log() {
    if [ "${VERBOSE}" = "1" ]; then
        echo "$1"
    else
        logger -t radxa-poe-fan "$1"
    fi
}

find_hwmon() {
    for hw in /sys/class/hwmon/hwmon*; do
        if [ -f "$hw/name" ] && grep -qi pwm "$hw/name"; then
            echo "$hw"
            return
        fi
    done
    echo "/sys/class/hwmon/hwmon10" # fallback
}

HWMON_PATH=$(find_hwmon)

cleanup() {
    echo 0 > "$HWMON_PATH/pwm1"
}
trap cleanup EXIT

# Set thermal policy to user_space to prevent interference
if [ -w /sys/class/thermal/thermal_zone0/policy ]; then
    echo "user_space" > /sys/class/thermal/thermal_zone0/policy
fi

echo 1 > "$HWMON_PATH/pwm1_enable"

log "Radxa PoE Fan Control Started"

while true; do
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP_RAW / 1000))

    PWM=${PWM_VALUES[${#PWM_VALUES[@]}-1]}
    for i in "${!TEMP_THRESHOLDS[@]}"; do
        if [ "$TEMP_C" -lt "${TEMP_THRESHOLDS[$i]}" ]; then
            PWM=${PWM_VALUES[$i]}
            break
        fi
    done

    echo 1 > "$HWMON_PATH/pwm1_enable"
    echo "$PWM" > "$HWMON_PATH/pwm1"

    log "$(date '+%H:%M:%S') - Temp: ${TEMP_C}°C, PWM: $PWM"
    sleep 2
done
