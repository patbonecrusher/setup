#!/usr/bin/env bash
#
# bootstrap.sh — reproducible fresh-Mac setup entrypoint.
#
# Idempotent: safe to re-run at any point. Each step checks before acting.
#
# Usage:
#   ./bootstrap.sh            Foundation only: Xcode CLT, Homebrew, chezmoi + gh,
#                             and `chezmoi init` (clones dotfiles source WITHOUT
#                             applying). Stop here to curate packages and sign
#                             into the Mac App Store before installing.
#   ./bootstrap.sh --apply    Also run `chezmoi apply` (installs all packages,
#                             casks, App Store apps, dotfiles, macOS tweaks).
#
# Env overrides:
#   GH_USER=patbonecrusher    GitHub user whose dotfiles repo chezmoi pulls.
#
# See RUNBOOK.md for the manual GUI steps (App Store sign-in, 1Password,
# app permissions) that cannot be scripted.

set -euo pipefail

# Must run as your normal user, NOT with sudo. Homebrew refuses to install as
# root and invokes sudo itself only for the steps that need it.
if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run bootstrap.sh with sudo / as root." >&2
  echo "Run it as your normal user: ./bootstrap.sh" >&2
  exit 1
fi

GH_USER="${GH_USER:-patbonecrusher}"
DO_APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) DO_APPLY=1 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done

log()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

# 1. Xcode Command Line Tools — required by Homebrew and most compilers.
ensure_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode CLT present: $(xcode-select -p)"
  else
    log "Installing Xcode Command Line Tools (GUI installer will appear)…"
    xcode-select --install || true
    echo "Finish the CLT installer window, then re-run this script."
    exit 1
  fi
}

# 2. Homebrew — package manager. Needs sudo once to create /opt/homebrew.
ensure_brew() {
  if [ -x /opt/homebrew/bin/brew ]; then
    log "Homebrew present"
  else
    log "Installing Homebrew (will prompt for your macOS password)…"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Persist brew on PATH for future login shells.
  local line='eval "$(/opt/homebrew/bin/brew shellenv)"'
  if ! grep -qsF "$line" "$HOME/.zprofile" 2>/dev/null; then
    log "Adding Homebrew to ~/.zprofile"
    printf '%s\n' "$line" >> "$HOME/.zprofile"
  fi
}

# 3. Core tooling needed to drive the rest of setup.
ensure_tools() {
  log "Installing chezmoi + gh"
  brew install chezmoi gh
}

# 4. chezmoi — pull dotfiles source. Apply (which installs everything) is
#    gated behind --apply so we can curate + sign into the App Store first.
ensure_chezmoi() {
  if [ "$DO_APPLY" -eq 1 ]; then
    log "chezmoi init --apply $GH_USER  (installs packages + dotfiles)"
    chezmoi init --apply "$GH_USER"
  else
    log "chezmoi init $GH_USER  (source only — review, then 'chezmoi apply')"
    chezmoi init "$GH_USER"
  fi
}

main() {
  ensure_clt
  ensure_brew
  ensure_tools
  ensure_chezmoi

  if [ "$DO_APPLY" -eq 1 ]; then
    log "Done. Next: run ./macos/defaults.sh, then see RUNBOOK.md for GUI steps."
  else
    cat <<NEXT

$(log "Foundation complete. Source cloned to ~/.local/share/chezmoi")
Next steps (see RUNBOOK.md):
  1. Sign into the Mac App Store (REQUIRED before App Store apps install).
  2. Curate packages:  chezmoi edit ~/.config  or edit
     ~/.local/share/chezmoi/.chezmoidata/packages.yaml
  3. Preview changes:  chezmoi diff
  4. Install:          ./bootstrap.sh --apply   (or: chezmoi apply)
NEXT
  fi
}

main
