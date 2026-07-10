#!/usr/bin/env bash
#
# macos/power.sh — battery/power management tweaks (pmset).
#
# Idempotent: safe to re-run. Uses `sudo pmset` (prompts for password / Touch ID).
# `-b` = battery only, `-c` = charger only, `-a` = both. We only touch battery so
# performance on AC is unchanged.
#
# Tested on macOS 26 (Apple Silicon). Run: sudo ./macos/power.sh
#
# NOTE: brightness, "Optimize video streaming on battery", and the Battery-Health
# charge limit are GUI-only (Apple exposes no pmset key) — set those in
# System Settings → Battery.

set -uo pipefail

log() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

###############################################################################
log "Low Power Mode → Only on Battery"
###############################################################################
# Cap clocks / trim background work when unplugged; full speed on AC.
sudo pmset -b lowpowermode 1
sudo pmset -c lowpowermode 0

###############################################################################
log "Disable Power Nap on battery"
###############################################################################
# Stop periodic wake-to-sync (mail/iCloud) while asleep on battery.
sudo pmset -b powernap 0

###############################################################################
log "Sleep timers on battery"
###############################################################################
# Display off after 2 min, disk after 10 min, on battery.
sudo pmset -b displaysleep 2
sudo pmset -b disksleep 10

# Optional (left OFF by default — weakens Find My / push while asleep):
#   Fewer network wakeups on battery:
# sudo pmset -b tcpkeepalive 0

log "Done. Current battery settings:"
pmset -g custom | sed -n '/Battery Power/,/AC Power/p'
