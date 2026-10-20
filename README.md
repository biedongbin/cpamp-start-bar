# CpampBar — CPAMP 菜单栏状态图标

[CPA / CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) + [CPAMP (CPA-Manager-Plus)](https://github.com/seakee/CPA-Manager-Plus) 的 macOS 菜单栏伴侣。单文件 Swift，零第三方依赖。

## 功能

| 能力 | 说明 |
|---|---|
| 状态图标 | 每 10 秒轮询 CPAMP `:18317/health`；健康=彩色 logo，异常=灰色禁用态 |
| 打开 CPAMP 面板 | `http://127.0.0.1:18317/management.html`（⌘1） |
| 打开 CPA 面板 | `http://127.0.0.1:8317/management.html`（⌘2） |
| 重启 CPAMP | `launchctl kickstart -k`（⌘R），适配 launchd 托管的 CPAMP |
| 查看日志 | Console 打开 `launchd.err.log`（⌘L） |
| 退出 | 只关菜单栏进程，后台服务不受影响（⌘Q） |

图标取自 CPAMP 官方 logo（去背景、透明通道）。

## 环境要求

- macOS 12+（Apple Silicon / Intel）
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
