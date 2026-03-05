#!/usr/bin/env zsh

battery=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
battery_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)

charging_icons=(󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)
discharging_icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)

# Exit if no battery found
[[ -z "$battery" ]] && exit 0

# Calculate icon index (1-10, zsh arrays are 1-indexed)
icon=$(( (battery + 9) / 10 ))
[[ $icon -lt 1 ]] && icon=1
[[ $icon -gt 10 ]] && icon=10

case "$battery_status" in
    Full)
        echo "${charging_icons[10]} Battery full"
        ;;
    Discharging)
        echo "${discharging_icons[$icon]} Discharging ${battery}%"
        ;;
    "Not charging")
        echo "${charging_icons[$icon]} Battery charged"
        ;;
    *)
        echo "${charging_icons[$icon]} Charging ${battery}%"
        ;;
esac
