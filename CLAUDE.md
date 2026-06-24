# mac-setup

Patrick's Mac provisioning. This directory holds **two separate git repos** plus Claude config:

| Path | Repo | Role |
|------|------|------|
| `dotfiles/` | `github.com/patbonecrusher/dotfiles` | **chezmoi source** — all dotfiles, shell config, scripts, package list |
| `setup/` | `github.com/patbonecrusher/setup` | **imperative macOS bootstrap** — `RUNBOOK.md`, `MACHINE-NOTES.md`, `macos/defaults.sh` (system `defaults write`s) |
| `.claude/` | — | Claude Code project config |

Both remotes are SSH (`git@github.com:...`), so plain `git push` works via SSH keys. Only commit/push when asked.

## chezmoi is the source of truth (chezmoi-first)

chezmoi's `sourceDir` is set to **`~/Projects/mac-setup/dotfiles`** (in `~/.config/chezmoi/chezmoi.toml`). There used to be a second clone at `~/.local/share/chezmoi` that drifted badly out of sync — it's retired (`~/.local/share/chezmoi.retired-bak`). **Edit only the dotfiles source here.**

Standard change flow for anything under `dotfiles/`:
1. Edit the **source** file (never the live `~` file directly).
2. `chezmoi apply --force <target>` (use `--force` since live files are often flagged as externally modified).
3. `cd dotfiles && git add … && git commit && git push`.

Source → target naming: `dot_zshrc`→`~/.zshrc`, `dot_config/X`→`~/.config/X`, `dot_local/scripts/executable_<name>`→`~/.local/scripts/<name>` (on PATH).

- **Aliases / shell functions:** `dotfiles/dot_config/aliases`
- **Shell scripts:** `dotfiles/dot_local/scripts/executable_<name>`
- **zsh config:** `dotfiles/dot_zshrc` (zoxide init must stay LAST)

## Packages / Homebrew bootstrap

- Declarative list: **`dotfiles/.chezmoidata/packages.yaml`** (`brews:` and `casks:`).
- `dotfiles/.chezmoiscripts/run_onchange_before_install-homebrew-packages.sh.tmpl` runs `brew bundle` from that list on `chezmoi apply`. Mac App Store apps (`mas`) are inline in that script.
- Casks install to **`/Applications`** via `HOMEBREW_CASK_OPTS` in `dotfiles/dot_config/homebrew/brew.env` — **never hardcode a username** in that path (a stale `/Users/patricklaplante` once caused `brew bundle` to relocate apps and break Zen's profile).
- To add one package: add it to `packages.yaml` **and** `brew install [--cask] <x>` (the full bundle on apply is idempotent now, but installing directly is faster).
- Watch for wrong cask names: e.g. Spark email is `readdle-spark` (plain `spark` is a different app).

## macOS system settings

Live in **`setup/macos/defaults.sh`** (NOT chezmoi). Edit there, run the relevant `defaults write` to apply now (script restarts Finder/Dock/SystemUIServer at the end), then commit/push in `setup/`. E.g. screenshots → clipboard is `com.apple.screencapture target = clipboard`.

## Terminal: Ghostty + tmux

- **Ghostty** config: `dotfiles/dot_config/ghostty/config`. Theme is **Django Reborn Again**; don't set an explicit `background`/`background-opacity`/`background-blur` — they override the theme and stop it loading. tmux-style keybinds use a `super+b` (⌘b) prefix for splits/tabs/nav. Right-click context menu works by default (`right-click-action = context-menu`); needs a real secondary-click (two-finger / ⌃-click). After config edits, **⌘Q and relaunch** — closing the window leaves a stale instance.
- **tmux** config: `dotfiles/dot_config/tmux/tmux.conf` (prefix is `C-b`, NOT ⌘b — Ghostty uses ⌘b, so the two don't collide). Reload/edit binds (`C-b r` / `C-b M`) point at `~/.config/tmux/tmux.conf` (there is no `~/.tmux.conf`). Pane bg is `default` so the Ghostty theme shows through — **never re-add a hardcoded `window-style`/`window-active-style` bg**. Modern settings in place: truecolor (`terminal-features RGB`), `allow-passthrough on` (yazi image previews), `set-clipboard on` (OSC52), `focus-events`, base-index 1.
- **tmux plugins** via TPM (`C-b I` to install): resurrect + **continuum** (`@continuum-restore on` = auto-save/restore), **tmux-yank**, **vim-tmux-navigator**. The last pairs with the nvim plugin in `dot_config/nvim/lua/plugins/tmux-navigator.lua` so `C-h/j/k/l` flows between nvim splits and tmux panes (overrides LazyVim's window-only maps).

## Environment quirks (important for running shell commands)

- Shells may print `zoxide: detected a possible configuration issue` (harmless) and previously `_alts_offer: command not found`. The latter is **fixed** (the `tool-alts.zsh` wrappers for `cat`/`du`/`ps`/`top` now fall back to the real command when `_alts_offer` isn't in scope) — but shells started *before* the fix keep the old inherited wrappers until restarted. In Bash tool calls it's still safe to start with `precmd_functions=(); preexec_functions=()` and pipe through `grep -vi 'zoxide\|_ZO_DOCTOR\|_alts_offer'` to keep output clean.
- `rm` is a **function** (in `dot_config/aliases`) that forwards to native macOS `/usr/bin/trash`, stripping `rm`-style flags. To really delete, use `/bin/rm`.
- nvim is **LazyVim**; nvim-treesitter is pinned to `branch=master` (`dotfiles/dot_config/nvim/lua/plugins/treesitter.lua`) — its new `main`-branch rewrite breaks this LazyVim. Don't let `:Lazy update` flip it back.
