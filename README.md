# setup

Reproducible bootstrap for a fresh macOS machine (Apple Silicon).

Dotfiles, packages, and most app/macOS config are managed by
[chezmoi](https://chezmoi.io) in **[patbonecrusher/dotfiles](https://github.com/patbonecrusher/dotfiles)**.
This repo owns the thin layer chezmoi can't: the **bootstrap** (install Xcode CLT →
Homebrew → chezmoi) and the **runbook** of manual GUI steps and ordering gotchas.

## Quick start

```sh
git clone https://github.com/patbonecrusher/setup ~/Projects/setup
~/Projects/setup/bootstrap.sh        # foundation only (no packages installed yet)
```

Then follow **[RUNBOOK.md](./RUNBOOK.md)** for the ordered steps (App Store sign-in,
`chezmoi apply` in a TTY, toolchains, macOS defaults, manual follow-ups).

`bootstrap.sh --apply` runs the full chezmoi apply too, but the interactive path in the
runbook is recommended for a first-time machine.

## Contents

| Path | Purpose |
|------|---------|
| `bootstrap.sh` | Idempotent entrypoint: Xcode CLT, Homebrew, `chezmoi`+`gh`, `chezmoi init`. |
| `macos/defaults.sh` | Opinionated macOS `defaults` (Finder, Dock, screenshots, trackpad…). |
| `RUNBOOK.md` | Ordered fresh-Mac procedure + every gotcha + manual GUI steps. |
| `MACHINE-NOTES.md` | Machine-specific deviations (curation, fixes) for exact reproduction. |
| `brew-audit.sh` | Categorized inventory of `brew leaves` + overlap/drift report → `PACKAGES.md`. |
| `PACKAGES.md` | Generated package catalog (run `brew-audit.sh` to refresh). |

## Relationship to dotfiles

```
setup (this repo, public)            patbonecrusher/dotfiles (chezmoi)
  bootstrap.sh  ── installs ──▶ brew, chezmoi
                └─ chezmoi init ─▶ pulls dotfiles + packages.yaml + scripts
  macos/defaults.sh                    dot_* configs, mas apps, TouchID, mise, …
  RUNBOOK.md  (the human glue)
```

No secrets live here. Credentials stay in 1Password / chezmoi `private_*` files (gitignored
or templated), never in this repo.
