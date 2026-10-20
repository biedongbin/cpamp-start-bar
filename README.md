# CpampBar — CPAMP 菜单栏管家

[CPA / CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) + [CPAMP (CPA-Manager-Plus)](https://github.com/seakee/CPA-Manager-Plus) 的 macOS 菜单栏伴侣。单文件 Swift，零第三方依赖。

## 下载安装

从 [Releases](https://github.com/biedongbin/cpamp-start-bar/releases/latest) 下载 `CpampBar.app.zip`，解压拖到 `~/Applications`（或 `/Applications`），双击运行。

## 功能

| 能力 | 说明 |
|---|---|
| 状态图标 | 每 10 秒轮询 CPAMP `:18317/health`；健康=正常图标，异常=半透明禁用态 |
| 打开 CPAMP 面板 | `http://127.0.0.1:18317/management.html`（⌘1） |
| 打开 CPA 面板 | `http://127.0.0.1:8317/management.html`（⌘2） |
| 重启 CPA 内核 | `launchctl kickstart` brew 服务 `sh.brew.cliproxyapi` |
| 重启 CPAMP | `launchctl kickstart`（⌘R），适配 launchd 托管的 CPAMP |
| 重启 CPA + CPAMP | 一键双重启 |
| 一键 Update CPA | `brew upgrade cliproxyapi` + 自动重启，完成弹通知 |
| 一键 Update CPAMP | 拉取最新 Release 替换二进制（保留 data 与配置）+ 自动重启 |
| 设置 · 开机自启 | SMAppService 登录项开关（勾选态实时显示） |
| 设置 · 更换图标 | 线条版（随主题变色）/ 彩色 logo / 简约圆点 / 自定义 PNG |
| 查看日志 | Console 打开 `launchd.err.log`（⌘L） |
| 退出 | 只关菜单栏进程，后台服务不受影响（⌘Q） |

线条版图标取自 CPAMP 官方 logo（去背景描边化，template 模式随深浅主题自动变色）。

## 环境要求

- macOS 13+（Apple Silicon / Intel，SMAppService 自启需要）
- CPA 运行在 `:8317`，CPAMP Manager Server 运行在 `:18317`
- CPAMP 由 launchd 托管（Label：`com.seakee.cpa-manager-plus`）

## 构建

```bash
git clone https://github.com/biedongbin/cpamp-start-bar
cd cpamp-start-bar
./Scripts/build.sh
open build/CpampBar.app
```

或只要二进制：

```bash
swiftc -O -o CpampBar Sources/CpampBar.swift
```

（图标资源在 `.app` 打包后生效；裸跑二进制时菜单栏不显示图片。）

## 开机自启

系统设置 → 通用 → 登录项 添加 `CpampBar.app`，或：

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/path/to/CpampBar.app", hidden:true}'
```

## 自定义端口/路径

改 `Sources/CpampBar.swift` 顶部常量后重新编译：

```swift
let cpampURL  = "http://127.0.0.1:18317/management.html"
let cpaURL    = "http://127.0.0.1:8317/management.html"
let healthURL = "http://127.0.0.1:18317/health"
```

## 目录结构

```
├── Sources/CpampBar.swift    # 全部逻辑（单文件）
├── Resources/
│   ├── icon-menubar*.png     # 菜单栏图标 1x/2x/3x
│   ├── cpamp-mark.svg        # 图标矢量源
│   └── Info.plist            # LSUIElement=true（不占 Dock）
└── Scripts/build.sh          # 编译 + 打包 .app + ad-hoc 签名
```

## 说明

- 本项目是 macOS 菜单栏 app，不是 CPA 插件——CPA 插件市场只接受 Go/C/Rust 动态库（C ABI），两者架构不同。
- 与 [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) 和 [CPA-Manager-Plus](https://github.com/seakee/CPA-Manager-Plus) 无隶属关系，logo 版权归 CPAMP 项目所有。

## License

MIT
