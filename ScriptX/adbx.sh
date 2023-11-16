#!/bin/sh
# adbx - A wrapper function for adb that automatically selects the device to use if multiple devices are connected.
#
# Usage:
#   adbx [options] <command> [<args>]
#
# Options:
#   -s <serialNumber>    - directs command to the device or emulator with the given serial number
#   -d <serialNumber>    - directs command to the only connected USB device with the given serial number
#   -e                  - directs command to the only running emulator
#   devices             - prints the list of all connected devices
#
# If multiple devices are connected, adbx will prompt the user to select the device to use.
#
# Returns:
#   0 if the command was successful, non-zero otherwise.
adbx() {
    case $(__number_of_connected_devices) in
        0)
            __echo "No devices connected"
            return 1
            ;;
        1)
            adb "$@"
            ;;
        *)
            if [ "$1" = "-s" ] || [ "$1" = "-d" ] || [ "$1" = "-e" ] || [ "$1" = "devices" ]; then
                adb "$@"
            else
                chosenDevice=$(__choose_device)
                adb -s "$chosenDevice" "$@"
            fi
            ;;
    esac
}

# Toggle layout bounds in developer options
adbx.bounds() {
    if [ "$1" != false ] && [ "$1" != true ]; then
        __echo "Wrong arguments, use true or false"
        return 1
    fi
    case $(__number_of_connected_devices) in
        0)
            __echo "No devices connected"
            return 1
            ;;
        1)
            adb shell setprop debug.layout "$1"
            adb shell service call activity 1599295570
            __echo "Toggle layout bounds: $1"
            ;;
        *)
            chosenDevice=$(__choose_device)
            adb -s "$chosenDevice" shell setprop debug.layout "$1"
            adb -s "$chosenDevice" shell service call activity 1599295570
            __echo "Toggle layout bounds enabled for $chosenDevice: $1"
            ;;
    esac
}

# Toggle animation in developer options
adbx.anim() {
    if [ "$1" != 0 ] && [ "$1" != 1 ]; then
        __echo "Wrong arguments, use 0 or 1"
        return 1
    fi
    case $(__number_of_connected_devices) in
        0)
            __echo "No devices connected"
            return 1
            ;;
        1)
            adb shell settings put global window_animation_scale $1
            adb shell settings put global transition_animation_scale $1
            adb shell settings put global animator_duration_scale $1
            __echo "Toggle animation: $1"
            ;;
        *)
            chosenDevice=$(__choose_device)
            adb -s "$chosenDevice" shell settings put global window_animation_scale $1
            adb -s "$chosenDevice" shell settings put global transition_animation_scale $1
            adb -s "$chosenDevice" shell settings put global animator_duration_scale $1
            __echo "Toggle animation for $chosenDevice: $1"
            ;;
    esac
}

adbx.anim.window() {
    if [ "$1" != 0 ] && [ "$1" != 1 ]; then
        __echo "Wrong arguments, use 0 or 1"
        return 1
    fi
    adbx shell settings put global window_animation_scale $1
}

adbx.anim.transition() {
    if [ "$1" != 0 ] && [ "$1" != 1 ]; then
        __echo "Wrong arguments, use 0 or 1"
        return 1
    fi
    adbx shell settings put global transition_animation_scale $1
}

adbx.anim.duration() {
    if [ "$1" != 0 ] && [ "$1" != 1 ]; then
        __echo "Wrong arguments, use 0 or 1"
        return 1
    fi
    adbx shell settings put global animator_duration_scale $1
}

# Get the name of the top activity
adbx.topactivity() {
    adbx shell dumpsys activity a . | grep -E 'mResumedActivity' | cut -d ' ' -f 8
}

# Get the width and height of the device in px and dp
adbx.wm.size() {
    case $(__number_of_connected_devices) in
        0)
            __echo "No devices connected"
            return 1
            ;;
        1)
            size=$(adb shell wm size)
            density=$(adb shell wm density)
            ;;
        *)
            chosenDevice=$(__choose_device)
            size=$(adb -s "$chosenDevice" shell wm size)
            density=$(adb -s "$chosenDevice" shell wm density)
            ;;
    esac
    widthPx=$(echo "$size" | cut -d ' ' -f 3 | cut -d 'x' -f 1)
    heightPx=$(echo "$size" | cut -d ' ' -f 3 | cut -d 'x' -f 2)
    dpi=$(echo "$density" | grep -o "Override density: [0-9]*" | cut -d ' ' -f 3)
    echo "Px: ${widthPx}x${heightPx}"
    # px = dp * (dpi / 160)
    widthDp=$(printf "%.0f" $(echo "scale=2; $widthPx / ($dpi / 160)" | bc))
    heightDp=$(printf "%.0f" $(echo "scale=2; $heightPx / ($dpi / 160)" | bc))
    echo "Dp: ${widthDp}x${heightDp}"
    echo "DPI: $dpi - $(__get_dpi_tag $(("$dpi")))"
}

# Get device DPI
adbx.wm.density () {
    adbx shell wm density
}

# Bug report
adbx.bugreport() {
    adbx bugreport
}

adbx.a11y() {
    if [ "$1" = false ]; then
        adbx shell settings put secure enabled_accessibility_services com.android.talkback/com.google.android.marvin.talkback.TalkBackService
    elif [ "$1" = true ]; then
        adbx shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
    else
        __echo "Wrong arguments, use true or false"
        return 1
    fi
}

adbx.server.kill() {
    adb kill-server
}

adbx.server.start() {
    adb start-server
}

adbx.server.restart() {
    adb kill-server
    adb start-server
}

adbx.ip() {
    adbx shell ifconfig wlan0
}

adbx.hardinfo() {
    device=$(__get_device)
    brand=$(adb -s $device shell getprop ro.product.brand)
    model=$(adb -s $device shell getprop ro.product.model)
    __echo "Brand: $brand ($model)"
    abi=$(adb -s $device shell getprop ro.product.cpu.abi)
    __echo "ABI: $abi"
    imei=$(adb -s $device shell service call iphonesubinfo 1 | awk -F "'" '{print $2}' | sed '1 d' | tr -d '.' | awk '{print}' ORS='')
}

adbx.softinfo() {
    device=$(__get_device)
    osVersion=$(adb -s $device shell getprop ro.build.version.release)
    sdkVersion=$(adb -s $device shell getprop ro.build.version.sdk)
    __echo "OS version: $osVersion (SDK: $sdkVersion)"
    kernelVersion=$(adb -s $device shell uname -r)
    __echo "Kernel version: $kernelVersion"
    buildNumber=$(adb -s $device shell getprop ro.build.display.id)
    __echo "Build number: $buildNumber"
}

adbx.battery() {
    device=$(__get_device)
    batteryLevel=$(adb -s $device shell dumpsys battery | grep level | awk '{print $2}')
    batteryStatus=$(adb -s $device shell dumpsys battery | grep status | awk '{print $2}')
    batteryHealth=$(adb -s $device shell dumpsys battery | grep health | awk '{print $2}')
    batteryTemp=$(adb -s $device shell dumpsys battery | grep temperature | awk '{print $2}')
    batteryVolt=$(adb -s $device shell dumpsys battery | grep voltage | awk '{print $2}')
    __echo "Battery status: $(__get_battery_status_tag $batteryStatus)"
    __echo "Battery level: $batteryLevel%"
}

# Deeplink
adbx.deeplink.open() {
    adbx shell am start -a android.intent.action.VIEW -d $1
}

adbx.deeplink.call() {
    adbx shell am start -a android.intent.action.CALL -d tel:$1
}

adbx.deeplink.sms() {
    adbx shell am start -a android.intent.action.VIEW -d sms:$1
}

# Top
adbx.top() {
    # if no arguments, run top on the device
    if [ $# -eq 0 ]; then
        adbx shell top
        return 0
    # else $1 is the name of the process
    else 
        adbx shell top -p \`pgrep "$1"\`
    fi
}

# Print the help message for all above functions
adbx.help() {
    echo "adbx - A wrapper function for adb that automatically selects the device to use if multiple devices are connected."
    echo ""
    echo "Usage:"
    echo "  adbx [options] <command> [<args>]"
    echo ""
    echo "Functions:"
    echo "  adbx.bounds()           - Toggle layout bounds in developer options"
    echo "  adbx.anim()             - Toggle animation in developer options"
    echo "  adbx.anim.window()      - Toggle window animation in developer options"
    echo "  adbx.anim.transition()  - Toggle transition animation in developer options"
    echo "  adbx.anim.duration()    - Toggle animator duration in developer options"
    echo "  adbx.topactivity()      - Get the name of the top activity"
    echo "  adbx.wm.size()          - Get the width and height of the device in px and dp"
    echo "  adbx.wm.density()       - Get device DPI"
    echo "  adbx.bugreport()        - Bug report"
    echo "  adbx.a11y()             - Toggle accessibility service"
    echo "  adbx.server.kill()      - Kill adb server"
    echo "  adbx.server.start()     - Start adb server"
    echo "  adbx.server.restart()   - Restart adb server"
    echo "  adbx.ip()               - Get device IP"
    echo "  adbx.hardinfo()         - Get device hardware info"
    echo "  adbx.softinfo()         - Get device software"
}

__echo() {
    echo "*** adbx: $1 ***"
}

__number_of_connected_devices() {
    adb devices | tail -n +2 | grep -c .
}

__choose_device() {
    adb devices | tail -n +2 | fzf | awk '{print $1}'
}

__get_device() {
    case $(__number_of_connected_devices) in
        0)
            # exit if no devices connected
            __echo "No devices connected"
            exit 0
            ;;
        1)
            # return the only device
            adb devices | tail -n +2 | awk '{print $1}'
            ;;
        *)
            # return the chosen device
            __choose_device
            ;;
    esac
}

__get_dpi_tag() {
    if [ "$1" -lt 160 ]; then
        echo "mdpi"
    elif [ "$1" -lt 240 ]; then
        echo "hdpi"
    elif [ "$1" -lt 320 ]; then
        echo "xhdpi"
    elif [ "$1" -lt 480 ]; then
        echo "xxhdpi"
    elif [ "$1" -lt 640 ]; then
        echo "xxxhdpi"
    else
        echo "unknown"
    fi
}

__get_battery_status_tag() {
    case "$1" in
        1)
            echo "Unknown"
            ;;
        2)
            echo "Charging"
            ;;
        3)
            echo "Discharging"
            ;;
        4)
            echo "Not charging"
            ;;
        5)
            echo "Full"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}