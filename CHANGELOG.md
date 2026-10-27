# Changelog

English | [简体中文](CHANGELOG.zh-CN.md)

All notable changes to this project are documented here. Versions follow [SemVer](https://semver.org/).

## [1.3.0] — 2026-10-27

### Added
- **Settings dialog (⌘,)**: one native dialog edits every configurable endpoint at once — CPAMP address, CPA address, CPAMP install dir, CPAMP service label, CPA service label. Leave a field empty to fall back to its default; **Reset Defaults** button clears all overrides.
- **Custom CPAMP / CPA addresses**: the panel URLs and the 10 s `/health` probe now derive from a configurable base URL, so non-default local ports work without editing source. Input is normalized (`http://` optional, `/management.html` and trailing `/` stripped) and rejected if not a valid URL. Status line and tooltip show the live `host:port`.
- All overrides persist in `UserDefaults`; defaults remain in the source constants.

### Changed
- `cpampPlist` / `logPath` now derive from the configurable install dir and service label.
- One-click **Update CPAMP** checks the install directory exists before unloading the LaunchAgent, and reports it if missing.

## [1.2.0] — 2026-10-20

### Added
- **UI language switching (中文 / English)**: new `Language / 语言` submenu at the top level; instant switch rebuilds the menu in place. Every menu item, status line, tooltip and notification is bilingual. Preference persisted in `UserDefaults`.

## [1.1.1] — 2026-10-20

### Changed
- **Flattened menu**: removed the "设置/Settings" submenu — **开机自启 (Autostart)** and **菜单栏图标 (Icon switcher)** now sit at the top level of the menu.
- README rewritten in dsh-claude-compat style: English main file + `README.zh-CN.md`, badge header, "10-second pitch" intro.

### Fixed
- **`openLog` action missing**: the method was dropped during the v1.1.0 rewrite (menu item had no target action); restored.

## [1.1.0] — 2026-10-20

### Added
- **Restart controls**: Restart CPA kernel / Restart CPAMP / Restart both — via `launchctl kickstart -k gui/<uid>/<label>`.
- **One-click Update CPA**: `brew upgrade cliproxyapi` → auto restart → system notification. Busy-lock prevents double-fire.
- **One-click Update CPAMP**: queries the latest GitHub Release tag, downloads `cpa-manager-plus_<ver>_darwin_arm64.tar.gz`, unloads the LaunchAgent, swaps the binary (preserves `data/` and `config.json`), reloads. Failure notifications on every step.
- **Settings** (now top-level): login-item autostart toggle via `SMAppService` with live checkmark state; menu bar icon switcher (line-art template / color logo / dot / custom PNG), persisted in `UserDefaults`.

### Changed
- Line-art template icon (`isTemplate = true`) — system tints it per menu bar theme (white on dark, black on light), replacing the low-contrast full-color icon in dark mode.

## [1.0.0] — 2026-10-20

### Added
- Initial release: single-file Swift menu bar app.
- Health icon polling CPAMP `:18317/health` every 10 s; healthy = colored logo, down = dimmed.
- Menu: open CPAMP/CPA panels, restart CPAMP, view logs in Console, quit (services unaffected).
- Icon extracted from the official CPAMP logo (background removed, 1x/2x/3x).
- `Scripts/build.sh`: compile + bundle `.app` + ad-hoc codesign.

### Notes
- Not a CPA plugin — the CPA plugin marketplace only accepts Go/C/Rust dynamic libraries (C ABI) running inside the CPA process. See README "Notes".
