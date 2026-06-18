# Fresh Mac Setup — Runbook

Ordered procedure to bring a brand-new Apple Silicon Mac to a fully-configured state.
Captures the gotchas hit on the M5 Pro setup (2026-06-16). Dotfiles, packages, and most
macOS config live in the chezmoi repo (`patbonecrusher/dotfiles`); this repo owns the
**bootstrap + the manual steps that can't be scripted**.

> Legend: 🖱️ = manual GUI step (cannot be automated) · ⌨️ = terminal step

---

## 0. Prerequisites 🖱️

- Apple Silicon Mac, macOS up to date.
- Sign into **iCloud / Apple ID** (System Settings).
- **Sign into the Mac App Store** — open App Store.app → Sign In.
  **This MUST happen before installing packages**, or every `mas` (App Store) app fails.

## 1. Bootstrap: Xcode CLT, Homebrew, chezmoi ⌨️

```sh
git clone https://github.com/patbonecrusher/setup ~/Projects/setup   # or download bootstrap.sh
~/Projects/setup/bootstrap.sh
```

Installs Xcode Command Line Tools (if missing), Homebrew (prompts for your **password**),
`chezmoi` + `gh`, then `chezmoi init patbonecrusher` (clones dotfiles source **without
applying**). Do **not** run with `sudo`.

## 2. (Optional) Curate packages ⌨️

Edit `~/.local/share/chezmoi/.chezmoidata/packages.yaml` and the `mas` list in
`.chezmoiscripts/run_onchange_before_install-homebrew-packages.sh.tmpl`. See
[MACHINE-NOTES.md](./MACHINE-NOTES.md) for the exact prunes used on the M5 Pro.

## 3. Apply: packages + dotfiles + App Store apps ⌨️ (in a REAL terminal)

> Run in Terminal/Ghostty — **not** in a background job — because `sudo` needs a TTY.

```sh
chezmoi apply
```

This installs all Homebrew formulae/casks, App Store apps, writes dotfiles, and enables
TouchID-for-sudo. Expect **password / Touch ID prompts** (xquartz, zerotier-one, the App
Store apps, the sudo tweak).

### Known failure modes (and fixes)
- **`mas` needs sudo on macOS 26** → must run in a TTY (above). In background it fails with
  "a terminal is required."
- **App Store apps not yet purchased on this Apple ID** → `mas` can't install them. "Get"
  them once in the App Store GUI, then re-run.
- **Untrusted third-party taps** (Homebrew 6.0) → `brew trust knqyf263/pet`,
  `brew trust patbonecrusher/splistgo`. (The patched dotfiles do this automatically.)
- **A failed package aborting the whole apply** → the patched package script uses
  `brew bundle ... || true`. If yours doesn't yet, dotfiles won't land until it succeeds;
  if needed, install stragglers directly (see MACHINE-NOTES).

## 4. Language toolchains ⌨️

chezmoi writes `~/.config/mise/config.toml` but does not install the tools:

```sh
mise install
# If Python's prebuilt fails attestation:
MISE_PYTHON_COMPILE=1 mise install python@<version>
```

## 5. GitHub + git identity ⌨️

```sh
gh auth login                          # GitHub.com → SSH or HTTPS → browser
git config --global user.name  "Patrick Laplante"
git config --global user.email "laplante.patrick@gmail.com"
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true
```

## 6. macOS system defaults ⌨️

```sh
~/Projects/setup/macos/defaults.sh
```

## 7. Manual GUI follow-ups 🖱️

- **1Password** — open and sign in (unlocks credentials; optionally enable the SSH agent).
- **Safari** → Settings → Advanced → "Show features for web developers" (the Develop menu
  can't be enabled via `defaults` — sandboxed).
- **System Settings → Lock Screen** — confirm "Require password after sleep" is set.
- Grant permissions when first launching: **Raycast, Hammerspoon, espanso** need
  Accessibility / Input Monitoring / Automation (System Settings → Privacy & Security).
- Sign into apps: **Slack, Arc/Zen, Obsidian, Reeder, Things**, etc.
- **espanso**: `espanso start` / grant Accessibility; **zerotier-one**: approve the system
  extension if prompted.

## 8. Verify ⌨️

```sh
brew list --formula | wc -l && brew list --cask | wc -l
mise ls                                   # go / node / python / rust present
mas list                                  # App Store apps
sudo -k && sudo true                      # Touch ID prompt should appear
exec zsh                                  # starship prompt, atuin history, aliases load
defaults read com.apple.dock autohide     # macOS defaults took
```
