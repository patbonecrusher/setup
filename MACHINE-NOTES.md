# Machine-specific notes — M5 Pro (2026-06-16)

Deviations applied to the chezmoi source on THIS machine only (not committed to
`patbonecrusher/dotfiles`). To reproduce this exact machine, apply these prunes to
`~/.local/share/chezmoi` after `chezmoi init` and before `chezmoi apply`.

## Curation: container runtime → colima + lima

Removed overlapping container runtimes, keeping colima + lima (+ docker CLI + compose).

`.chezmoidata/packages.yaml` casks removed:
- `docker`   (Docker Desktop)
- `orbstack`

Kept (brews): `lima`, `colima`, `docker`, `docker-compose`.

## Curation: App Store prunes

`.chezmoiscripts/run_onchange_before_install-homebrew-packages.sh.tmpl` — removed:
- `mas 'Caffeinated', id: 1362171212`  (duplicate of the `caffeine` cask)
- `mas 'Xcode', id: 497799835`         (full Xcode already installed on this machine)

## Upstream breakage fix: neofetch → fastfetch

`neofetch` was removed from Homebrew (discontinued 2024). Replaced with `fastfetch`
(maintained drop-in successor) in `.chezmoidata/packages.yaml`. **This should also be
fixed upstream in the chezmoi repo** (it breaks every machine), so it's folded into the
chezmoi-patch step. Note: fastfetch uses its own config, not `~/.config/neofetch/`.

## Structural fix: package install must not block dotfiles

The chezmoi package script (`run_onchange_before_install-homebrew-packages.sh.tmpl`) returned
`brew bundle`'s exit code. Any package failure (e.g. an iWork app not yet acquired) made the
`before` script exit non-zero, which **aborts `chezmoi apply` before dotfiles are written**.
Fixed locally by making the bundle best-effort: `brew bundle ... <<EOF || true`. **Recommend
upstream** (chezmoi patch step) — ideally split brews/casks (fail visibly) from `mas` (best-effort).

## macOS 26 gotcha: `mas install` now requires sudo

On macOS 26, `mas install` invokes sudo, so it fails in any non-TTY/background context with
"a terminal is required." Run `chezmoi apply` in a real terminal so sudo prompts work.

## App Store apps needing a manual "Get" first

`mas` cannot install apps never acquired on the Apple ID. These errored "No apps found for
ADAM ID" and must be downloaded once via the App Store GUI, then `mas install <id>` (or re-apply):
- Keynote (409183694), Numbers (409203825), Pages (409201541) — verify/Get in App Store.

## Homebrew 6.0 gotcha: third-party taps must be trusted

Homebrew 6.0 refuses to load formulae from untrusted third-party taps
("Refusing to load formula ... from untrusted tap"). This aborts `brew bundle`'s fetch
phase. Trust required before bundle:
- `brew trust patbonecrusher/splistgo`   (kept — Pat's own serial-port tool)
For reproducibility this `brew trust` must run BEFORE the package bundle (add to bootstrap
or a chezmoi pre-script). `knqyf263/pet` was the other untrusted tap — **removed** (`pet` dropped
from packages.yaml; not wanted).

## Cask renames (updated in packages.yaml)

`gitup`→`gitup-app`, `lasso`→`lasso-app`, `xcodes`→`xcodes-app`, `zen-browser`→`zen`.
Old names still resolve with a warning; updated for clean runs. Worth pushing upstream.

## mise: tools not auto-installed; Python prebuilt attestation failure

chezmoi applies `~/.config/mise/config.toml` but does NOT run `mise install`, so run it
once post-apply. Python 3.12.5's prebuilt (python-build-standalone) failed mise's new
attestation check ("No GitHub artifact attestations found"). Workaround that worked:
`MISE_PYTHON_COMPILE=1 mise install python@3.12.5` (compiles from source; brew already
provides openssl@3/readline/sqlite/xz/zlib build deps). go/node/rust installed fine prebuilt.

## macOS defaults applied (macos/defaults.sh)

Applied & verified on macOS 26: Finder, Dock, Screenshots, Save/Print panels, trackpad
tap-to-click. Two need manual GUI follow-up:
- **Safari Develop menu**: `defaults` blocked (sandboxed container). Enable via Safari >
  Settings > Advanced > "Show features for web developers".
- **Password after sleep**: `com.apple.screensaver askForPassword` written but may be cosmetic;
  confirm in System Settings > Lock Screen.

## Notes

- Full Xcode (not just CLT) is installed at `/Applications/Xcode.app`.
- If you later run `chezmoi update`, these uncommitted local edits may be overwritten;
  re-apply from this file if so.
