#!/bin/sh
# A wrapper for adb
# If there are multiple devices and emulators connected, then prompt user to choose one
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
            if [ "$1" = "-s" ]; then
                adb "$@"
            else
                chosenDevice=$(__choose_device)
                adb -s "$chosenDevice" "$@"
            fi
            ;;
    esac
}

# Toggle layout bounds in developer options
adbx.layout.bounds() {
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
adbx.animation() {
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

adbx.animation.window() {
    if [ "$1" != 0 ] && [ "$1" != 1 ]; then
        __echo "Wrong arguments, use 0 or 1"
        return 1
    fi
    adbx shell settings put global window_animation_scale $1
}

adbx.animation.transition() {
    if [ "$1" != 0 ] && [ "$1" != 1 ]; then
        __echo "Wrong arguments, use 0 or 1"
        return 1
    fi
    adbx shell settings put global transition_animation_scale $1
}

adbx.animation.duration() {
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

adbx.accessibility() {
    if [ "$1" = false ]; then
        adbx shell settings put secure enabled_accessibility_services com.android.talkback/com.google.android.marvin.talkback.TalkBackService
    elif [ "$1" = true ]; then
        adbx shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
    else
        __echo "Wrong arguments, use true or false"
        return 1
    fi
}

# A wrapper for echo
# format: *** adbx: {message} ***
__echo() {
    # if parameter count is 2, then it's a level and a message
    echo "*** adbx: $1 ***"
}

__number_of_connected_devices() {
    adb devices | tail -n +2 | grep -c .
}

__choose_device() {
    adb devices | tail -n +2 | fzf | awk '{print $1}'
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