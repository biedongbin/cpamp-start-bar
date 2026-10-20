<p align="center">
  <img src="Resources/icon-style-color@3x.png" width="96" alt="CpampBar">
</p>

<h1 align="center">CpampBar</h1>

<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/%F0%9F%8C%90_English-Read_in_English-blue?style=for-the-badge" alt="English"></a>
  <img src="https://img.shields.io/badge/version-1.1.1-blue?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?style=flat-square" alt="macOS 13+">
  <img src="https://img.shields.io/badge/license-MIT-orange?style=flat-square" alt="MIT">
</p>

> **[CPA / CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) 与 [CPAMP (CPA-Manager-Plus)](https://github.com/seakee/CPA-Manager-Plus) 的 macOS 菜单栏管家。**
> 菜单栏一眼看健康态，一键重启双内核、一键更新，零第三方依赖。

---

## 十秒简介

你跑着 CPA（`:8317`）和 CPAMP Manager Server（`:18317`）。查健康要开浏览器、重启服务要敲终端、更新要 brew 和手动下 release——全散在各处。

**CpampBar 把这些收进一个菜单。** 菜单栏图标实时反映健康（每 10 秒刷新），重启按钮、一键更新、开机自启、换图标。一个约 100 KB 的 app，无 Electron，后台只有一个 `Timer`。

## 安装

**Homebrew（推荐）：**

```bash
brew install --cask biedongbin/tap/cpampbar
```

> cask 配方存放在 [biedongbin/homebrew-tap](https://github.com/biedongbin/homebrew-tap) 仓库（`Casks/cpampbar.rb`），含 sha256 校验、`livecheck` 自动追踪新版，并已在 postflight 中自动解除 Gatekeeper 隔离。

cask 已自动解除 Gatekeeper 隔离（app 为 ad-hoc 签名，无 Apple Developer ID）。发新版后 `brew upgrade --cask cpampbar` 升级——或直接用 app 内的「一键 Update」更新 CPA/CPAMP。

**手动安装：**从 [Releases](https://github.com/biedongbin/cpamp-start-bar/releases/latest) 下载 `CpampBar.app.zip`，解压拖进 `~/Applications`。app 为 ad-hoc 签名，macOS 首次打开可能要求放行：右键 app → **打开**，或在 **系统设置 → 隐私与安全性** 里允许。

## 功能

| | 功能 | 说明 |
|---|---|---|
| 🟢 | **健康图标** | 每 10 秒轮询 CPAMP `:18317/health`；健康=正常图标，异常=半透明 |
| 🌐 | **打开面板** | CPAMP `:18317`（⌘1）· CPA `:8317`（⌘2） |
| 🔄 | **重启** | CPA 内核 · CPAMP · 双重启——`launchctl kickstart` 实现 |
| ⬆️ | **一键 Update CPA** | `brew upgrade cliproxyapi` + 自动重启 + 系统通知 |
| ⬆️ | **一键 Update CPAMP** | 拉取最新 GitHub Release 替换二进制（保留 `data/` 与 `config.json`），自动重启 |
| ⚙️ | **开机自启** | SMAppService 登录项开关，勾选态实时显示 |
| 🎨 | **菜单栏图标** | 线条版（随主题变色）· 彩色 logo · 简约圆点 · 自定义 PNG |
| 🌐 | **界面语言** | 中文 / English 菜单内即时切换 |
| 📜 | **查看日志** | Console 打开 `launchd.err.log`（⌘L） |
| 🚪 | **退出** | 只关菜单栏进程，后台服务继续跑（⌘Q） |

## 环境要求

- macOS 13+（Apple Silicon / Intel）
- CPA 跑在 `:8317`（Homebrew 服务），CPAMP Manager Server 跑在 `:18317`（launchd label `com.seakee.cpa-manager-plus`）
- CPAMP 安装在 `~/cpamp/cpamp`（一键更新路径依赖）

## 构建

```bash
git clone https://github.com/biedongbin/cpamp-start-bar
cd cpamp-start-bar
./Scripts/build.sh
open build/CpampBar.app
```

脚本背后一条链：`swiftc` 编译 → 打包 `.app` → ad-hoc 签名。

或只要裸二进制（菜单栏图片需要 `.app` bundle 资源）：

```bash
swiftc -O -o CpampBar Sources/CpampBar.swift
```

## 自定义端口与路径

常量集中在 `Sources/CpampBar.swift` 顶部：

```swift
let cpampPanel = "http://127.0.0.1:18317/management.html"
let cpaPanel   = "http://127.0.0.1:8317/management.html"
let cpaLabel   = "sh.brew.cliproxyapi"               // brew 服务 label
let cpampLabel = "com.seakee.cpa-manager-plus"       // CPAMP LaunchAgent label
let cpampDir   = "~/cpamp/cpamp"                     // 一键更新用
```

改完 `./Scripts/build.sh` 重新构建。

## 目录结构

```
├── Sources/CpampBar.swift     # 全部逻辑，单文件
├── Resources/
│   ├── icon-style-line*.png   # 菜单栏图标，线条版 template（1x/2x/3x）
│   ├── icon-style-color*.png  # 菜单栏图标，彩色 logo
│   └── Info.plist             # LSUIElement=true（不占 Dock）
└── Scripts/build.sh           # 编译 + 打包 + ad-hoc 签名
```

## 说明

- 本项目是 **macOS 菜单栏 app，不是 CPA 插件**。CPA 插件市场只接受运行在 CPA 进程内的 Go/C/Rust 动态库（C ABI）——它们无法重启/更新自己的宿主，也无法创建菜单栏。分层不同，此为设计使然。
- 与 [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI)、[CPA-Manager-Plus](https://github.com/seakee/CPA-Manager-Plus) 无隶属关系，CPAMP logo 版权归其项目所有。
- 版本历史见 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)。English docs: [README.md](README.md)。

## 致谢

- [Linux.do](https://linux.do) — 社区
- [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) — CpampBar 所管理的代理内核
- [CPA-Manager-Plus](https://github.com/seakee/CPA-Manager-Plus) — 管理面板服务端，CPAMP logo 版权归其项目所有

## License

[MIT](LICENSE)

## ⭐ Star History

若此项目对你有帮助，请给它一个 ⭐ —— 这是我们持续改进的动力。

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
