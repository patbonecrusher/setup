#!/usr/bin/env bash
#
# macos/defaults.sh — opinionated macOS system defaults.
#
# Idempotent: safe to re-run. Applies user preferences via `defaults write`,
# then restarts affected UI processes. Some keys are sandboxed/locked on recent
# macOS (noted inline) and may require a GUI toggle instead.
#
# Tested on macOS 26 (Apple Silicon). Run: ./macos/defaults.sh

set -uo pipefail

log() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

# Close System Settings to avoid it overwriting changes on exit.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

###############################################################################
log "Finder"
###############################################################################
# Show all filename extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show hidden files.
defaults write com.apple.finder AppleShowAllFiles -bool true
# Path bar + status bar.
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Keep folders on top when sorting by name.
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder by default (instead of the whole Mac).
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Use list view by default (Nlsv | icnv | clmv | glyv).
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Don't write .DS_Store on network or USB volumes.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
log "Dock"
###############################################################################
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock tilesize -int 44
# Minimize windows into their application's icon.
defaults write com.apple.dock minimize-to-application -bool true
# Don't show recently-used apps in the Dock.
defaults write com.apple.dock show-recents -bool false
# Don't automatically rearrange Spaces based on most recent use.
defaults write com.apple.dock mru-spaces -bool false

###############################################################################
log "Screenshots"
###############################################################################
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
log "Save / Print panels"
###############################################################################
# Expand save and print panels by default.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
# Save new documents to disk (not iCloud) by default.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

###############################################################################
log "Security: require password after sleep/screensaver"
###############################################################################
# NOTE: on recent macOS these keys are often ignored via `defaults`; if the
# verification shows they didn't take, set in System Settings > Lock Screen.
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

###############################################################################
log "Trackpad: tap to click + three-finger drag"
###############################################################################
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Three-finger drag (accessibility gesture).
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

###############################################################################
log "Safari: developer settings"
###############################################################################
# NOTE: Safari prefs are sandboxed; these only work if the running terminal has
# Full Disk Access. If verification fails, enable via Safari > Settings >
# Advanced > "Show features for web developers".
defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || true
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true 2>/dev/null || true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true 2>/dev/null || true

###############################################################################
log "Restarting affected apps"
###############################################################################
for app in Finder Dock SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

log "Done. Some changes require a logout/restart to fully take effect."
