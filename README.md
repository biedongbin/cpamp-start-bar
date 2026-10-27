<p align="center">
  <img src="Resources/icon-style-color@3x.png" width="96" alt="CpampBar">
</p>

<h1 align="center">CpampBar</h1>

<p align="center">
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/%F0%9F%8C%90_%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-阅读中文版-red?style=for-the-badge" alt="简体中文"></a>
  <img src="https://img.shields.io/badge/version-1.3.0-blue?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?style=flat-square" alt="macOS 13+">
  <img src="https://img.shields.io/badge/license-MIT-orange?style=flat-square" alt="MIT">
</p>

> **A single-file Swift menu bar companion for [CPA / CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) and [CPAMP (CPA-Manager-Plus)](https://github.com/seakee/CPA-Manager-Plus).**
> Health at a glance, restart either core, one-click updates — right from your menu bar. Zero third-party dependencies.

---

## The 10-second pitch

You run CPA on `:8317` and the CPAMP Manager Server on `:18317`. Opening a browser to check health, restarting services from the terminal, updating via brew and release downloads — all of it scattered.

**CpampBar puts it in one menu.** Health state on the menu bar icon (refreshed every 10 s), restart buttons, one-click updates, autostart and icon switching. One ~100 KB app, no Electron, no background daemons beyond one `Timer`.

## Install

**Homebrew (recommended):**

```bash
brew install --cask biedongbin/tap/cpampbar
```

> Cask lives in the [biedongbin/homebrew-tap](https://github.com/biedongbin/homebrew-tap) repository (`Casks/cpampbar.rb`), with sha256 checksum, `livecheck` and a postflight that removes the Gatekeeper quarantine.

The cask removes the Gatekeeper quarantine automatically (the app is ad-hoc signed; no Apple Developer ID). Upgrades via `brew upgrade --cask cpampbar` once a new release ships — or just use the in-app **Update** items for CPA/CPAMP.

**Manual:** download `CpampBar.app.zip` from [Releases](https://github.com/biedongbin/cpamp-start-bar/releases/latest), unzip, drop into `~/Applications`. Because the app is ad-hoc signed, macOS may ask you to approve it on first launch: right-click the app → **Open**, or allow it in **System Settings → Privacy & Security**.

## Features

| | Feature | Details |
|---|---|---|
| 🟢 | **Health icon** | Polls CPAMP `:18317/health` every 10 s; healthy = normal icon, down = dimmed |
| 🌐 | **Open panels** | CPAMP `:18317` (⌘1) · CPA `:8317` (⌘2) |
| 🔄 | **Restart** | CPA kernel · CPAMP · both — via `launchctl kickstart` |
| ⬆️ | **One-click Update CPA** | `brew upgrade cliproxyapi` + auto restart + system notification |
| ⬆️ | **One-click Update CPAMP** | Fetches the latest GitHub Release, swaps the binary (keeps `data/` and `config.json`), restarts |
| ⚙️ | **Settings (⌘,)** | One dialog edits CPAMP/CPA addresses, install dir and service labels — custom ports, no rebuild |
| ⚙️ | **Autostart** | Login-item toggle via `SMAppService`, checkmark reflects live state |
| 🎨 | **Icon switcher** | Line-art (theme-adaptive template) · Color logo · Simple dot · Custom PNG |
| 🌐 | **UI language** | 中文 / English switch in the menu, applies instantly |
| 📜 | **Logs** | Opens `launchd.err.log` in Console (⌘L) |
| 🚪 | **Quit** | Kills only the menu bar; background services keep running (⌘Q) |

## Requirements

- macOS 13+ (Apple Silicon / Intel)
- CPA on `:8317` (Homebrew service) and CPAMP Manager Server on `:18317` — both configurable in **Settings…**
- CPAMP installed at `~/cpamp/cpamp` (for the one-click update path; also configurable)

## Build

```bash
git clone https://github.com/biedongbin/cpamp-start-bar
cd cpamp-start-bar
./Scripts/build.sh
open build/CpampBar.app
```

Single command chain behind the script: `swiftc` → bundle → ad-hoc codesign.

Or bare binary (menu bar image needs the `.app` bundle resources):

```bash
swiftc -O -o CpampBar Sources/CpampBar.swift
```

## Customizing endpoints

Pick **Settings… (⌘,)** from the menu. One dialog edits everything at once — no rebuild needed:

| Field | Default | Notes |
|---|---|---|
| CPAMP address | `http://127.0.0.1:18317` | Panel URL + `/health` probe; `http://` may be omitted |
| CPA address | `http://127.0.0.1:8317` | Panel URL |
| CPAMP install dir | `~/cpamp/cpamp` | Used by one-click Update CPAMP |
| CPAMP service label | `com.seakee.cpa-manager-plus` | `~/Library/LaunchAgents/<label>.plist` |
| CPA service label | `sh.brew.cliproxyapi` | Homebrew service label |

Leave a field empty to use its default. **Reset Defaults** clears all overrides. Overrides persist in `UserDefaults` (`~/Library/Preferences/com.biedongbin.cpampbar.plist`).

The defaults still live as constants at the top of `Sources/CpampBar.swift` (`defaultCpampBase`, `defaultCpaBase`, …) if you'd rather change the shipped baseline; rebuild with `./Scripts/build.sh`.

## Directory layout

```
├── Sources/CpampBar.swift     # All logic, single file
├── Resources/
│   ├── icon-style-line*.png   # Menu bar icon, line-art template (1x/2x/3x)
│   ├── icon-style-color*.png  # Menu bar icon, full-color logo
│   └── Info.plist             # LSUIElement=true (no Dock icon)
└── Scripts/build.sh           # Compile + bundle + ad-hoc sign
```

## Notes

- This is a **macOS menu bar app, not a CPA plugin**. The CPA plugin marketplace accepts only Go/C/Rust dynamic libraries (C ABI) that run inside the CPA process — they cannot restart/update their own host, and cannot create a menu bar. Different layer, by design.
- Not affiliated with [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) or [CPA-Manager-Plus](https://github.com/seakee/CPA-Manager-Plus). The CPAMP logo belongs to its project.
- See [CHANGELOG.md](CHANGELOG.md) for version history. 简体中文说明见 [README.zh-CN.md](README.zh-CN.md)。

## Acknowledgments

- [Linux.do](https://linux.do) — community
- [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) — the proxy kernel CpampBar manages
- [CPA-Manager-Plus](https://github.com/seakee/CPA-Manager-Plus) — the manager server; the CPAMP logo belongs to its project

## License

[MIT](LICENSE)

## ⭐ Star History

If this project helps you, please give it a ⭐ — it motivates us to keep improving.

<p align="center">
  <img src="https://img.shields.io/github/stars/biedongbin/cpamp-start-bar?style=for-the-badge&logo=github&color=gold" alt="GitHub Stars">
  <img src="https://img.shields.io/github/forks/biedongbin/cpamp-start-bar?style=for-the-badge&logo=github" alt="GitHub Forks">
  <img src="https://img.shields.io/github/watchers/biedongbin/cpamp-start-bar?style=for-the-badge&logo=github" alt="GitHub Watchers">
</p>

<div align="center">
  <a href="https://www.star-history.com/#biedongbin/cpamp-start-bar&Date">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=biedongbin/cpamp-start-bar&type=Date&theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=biedongbin/cpamp-start-bar&type=Date" />
      <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=biedongbin/cpamp-start-bar&type=Date" width="760" />
    </picture>
  </a>
</div>
