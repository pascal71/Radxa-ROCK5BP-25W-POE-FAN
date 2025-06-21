#!/bin/bash

# Set thermal policy to user_space to prevent interference
echo "user_space" > /sys/class/thermal/thermal_zone0/policy 2>/dev/null

# Enable PWM control
echo 1 > /sys/class/hwmon/hwmon10/pwm1_enable

echo "Radxa PoE Fan Control Started"

while true; do
    # Read temperature in millidegrees
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP_RAW / 1000))
    
    # Set fan speed based on temperature
    if [ $TEMP_C -lt 60 ]; then
        PWM=0
    elif [ $TEMP_C -lt 65 ]; then
        PWM=64    # 25%
    elif [ $TEMP_C -lt 70 ]; then
        PWM=128   # 50%
    elif [ $TEMP_C -lt 75 ]; then
        PWM=192   # 75%
    else
        PWM=255   # 100%
    fi
    
    # Ensure PWM is enabled and set the value
    echo 1 > /sys/class/hwmon/hwmon10/pwm1_enable
    echo $PWM > /sys/class/hwmon/hwmon10/pwm1
    
    # Debug output
    echo "$(date '+%H:%M:%S') - Temp: ${TEMP_C}°C, PWM: $PWM"
    
    sleep 2
done
