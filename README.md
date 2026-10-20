<p align="center">
  <img src="Resources/icon-style-color@3x.png" width="96" alt="CpampBar">
</p>

<h1 align="center">CpampBar</h1>

<p align="center">
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/%F0%9F%8C%90_%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-阅读中文版-red?style=for-the-badge" alt="简体中文"></a>
  <img src="https://img.shields.io/badge/version-1.1.1-blue?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?style=flat-square" alt="macOS 13+">
  <img src="https://img.shields.io/badge/license-MIT-orange?style=flat-square" alt="MIT">
</p>

> **A single-file Swift menu bar companion for [CPA / CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) and [CPAMP (CPA-Manager-Plus)](https://github.com/seakee/CPA-Manager-Plus).**
> Health at a glance, restart either core, one-click updates — right from your menu bar. Zero third-party dependencies.

---

## The 10-second pitch

You run CPA on `:8317` and the CPAMP Manager Server on `:18317`. Opening a browser to check health, restarting services from the terminal, updating via brew and release downloads — all of it scattered.

**CpampBar puts it in one menu.** Health state on the menu bar icon (refreshed every 10 s), restart buttons, one-click updates, autostart and icon switching. One ~100 KB app, no Electron, no background daemons beyond one `Timer`.

## Features

| | Feature | Details |
|---|---|---|
| 🟢 | **Health icon** | Polls CPAMP `:18317/health` every 10 s; healthy = normal icon, down = dimmed |
| 🌐 | **Open panels** | CPAMP `:18317` (⌘1) · CPA `:8317` (⌘2) |
| 🔄 | **Restart** | CPA kernel · CPAMP · both — via `launchctl kickstart` |
| ⬆️ | **One-click Update CPA** | `brew upgrade cliproxyapi` + auto restart + system notification |
| ⬆️ | **One-click Update CPAMP** | Fetches the latest GitHub Release, swaps the binary (keeps `data/` and `config.json`), restarts |
| ⚙️ | **Autostart** | Login-item toggle via `SMAppService`, checkmark reflects live state |
| 🎨 | **Icon switcher** | Line-art (theme-adaptive template) · Color logo · Simple dot · Custom PNG |
| 📜 | **Logs** | Opens `launchd.err.log` in Console (⌘L) |
| 🚪 | **Quit** | Kills only the menu bar; background services keep running (⌘Q) |

## Requirements

- macOS 13+ (Apple Silicon / Intel)
- CPA running on `:8317` (Homebrew service), CPAMP Manager Server on `:18317` under launchd label `com.seakee.cpa-manager-plus`
- CPAMP installed at `~/cpamp/cpamp` (for the one-click update path)

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

## Install

Download `CpampBar.app.zip` from [Releases](https://github.com/biedongbin/cpamp-start-bar/releases/latest), unzip, drop into `~/Applications`, double-click. For autostart, toggle **开机自启** in the menu (uses SMAppService).

## Customizing endpoints

All constants live at the top of `Sources/CpampBar.swift`:

```swift
let cpampPanel = "http://127.0.0.1:18317/management.html"
let cpaPanel   = "http://127.0.0.1:8317/management.html"
let cpaLabel   = "sh.brew.cliproxyapi"               // brew service label
let cpampLabel = "com.seakee.cpa-manager-plus"       // CPAMP LaunchAgent label
let cpampDir   = "~/cpamp/cpamp"                     // for one-click update
```

Edit, then `./Scripts/build.sh`.

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

## License

[MIT](LICENSE)
