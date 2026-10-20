# 更新日志

[English](CHANGELOG.md) | 简体中文

本文件记录本项目的全部显著变更。版本号遵循 [SemVer](https://semver.org/)。

## [1.2.0] — 2026-10-20

### 新增
- **界面语言切换（中文 / English）**：主菜单新增 `语言 / Language` 子菜单，切换即时重建菜单生效。全部菜单项、状态行、tooltip、系统通知均双语。偏好存 `UserDefaults`。

## [1.1.1] — 2026-10-20

### 变更
- **菜单扁平化**：移除「设置」子菜单层级——**开机自启**与**菜单栏图标**直接挂在主菜单。
- README 重写为 dsh-claude-compat 风格：英文主文件 + `README.zh-CN.md`、徽章头图、十秒简介。

### 修复
- **`openLog` 动作丢失**：v1.1.0 改写时方法被遗漏（菜单项没有目标动作），已补回。

## [1.1.0] — 2026-10-20

### 新增
- **重启三连**：重启 CPA 内核 / 重启 CPAMP / 双重启——`launchctl kickstart -k gui/<uid>/<label>` 实现。
- **一键 Update CPA**：`brew upgrade cliproxyapi` → 自动重启 → 系统通知。忙态锁防止重复触发。
- **一键 Update CPAMP**：查询最新 GitHub Release tag → 下载 `cpa-manager-plus_<ver>_darwin_arm64.tar.gz` → 卸载 LaunchAgent → 替换二进制（保留 `data/` 与 `config.json`）→ 重载。每步失败均有通知。
- **设置项**（现已顶层直达）：SMAppService 登录项自启开关（勾选态实时显示）；菜单栏图标四选（线条版 template / 彩色 logo / 圆点 / 自定义 PNG），选择存 `UserDefaults`。

### 变更
- 线条版 template 图标（`isTemplate = true`）——系统按菜单栏主题自动着色（深色栏白线、浅色栏黑线），替代深色模式下几乎不可见的彩色图标。

## [1.0.0] — 2026-10-20

### 新增
- 首发：单文件 Swift 菜单栏 app。
- 健康图标：每 10 秒轮询 CPAMP `:18317/health`；健康=彩色 logo，异常=半透明。
- 菜单：打开双面板、重启 CPAMP、Console 看日志、退出（服务不受影响）。
- 图标取自 CPAMP 官方 logo（去背景，1x/2x/3x）。
- `Scripts/build.sh`：编译 + 打包 + ad-hoc 签名。

### 备注
- 不是 CPA 插件——CPA 插件市场只接受运行在 CPA 进程内的 Go/C/Rust 动态库（C ABI）。见 README「说明」。
