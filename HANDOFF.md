# CpampBar 交接文档（HANDOFF）

> 供后续会话在 `~/workspace/github/cpampstartbar` 目录恢复上下文用。
> ⚠️ 实际磁盘路径是 `~/workspace/github/cpamp-start-bar`（带连字符），`cpampstartbar` 是指向它的符号链接。

最后更新：2026-10-20 · 项目版本 v1.2.0

---

## 1. 项目是什么

**CpampBar** — CPA / CLIProxyAPI + CPAMP (CPA-Manager-Plus) 的 macOS 菜单栏管家。
单文件 Swift（`Sources/CpampBar.swift`，约 430 行），零第三方依赖。

| 能力 | 说明 |
|---|---|
| 健康图标 | 10s 轮询 CPAMP `:18317/health`；异常=图标半透明 |
| 面板直达 | CPAMP `:18317`（⌘1）/ CPA `:8317`（⌘2） |
| 重启三连 | CPA 内核 / CPAMP / 双重启（`launchctl kickstart`） |
| 一键更新 | CPA：`brew upgrade cliproxyapi`；CPAMP：拉 release 替换二进制（保留 data） |
| 开机自启 | SMAppService 勾选开关 |
| 图标四选 | 线条版(template 随主题) / 彩色 / 圆点 / 自定义 PNG |
| 中英双语 | `语言 / Language` 子菜单即时切换，UserDefaults 持久化 |
| 应用图标 | 深蓝渐变底 + 白色线条 CPAMP 标（AppIcon.icns） |

## 2. 仓库与发布渠道

| 项 | 值 |
|---|---|
| 主仓库 | https://github.com/biedongbin/cpamp-start-bar |
| Tap 仓库 | https://github.com/biedongbin/homebrew-tap（`Casks/cpampbar.rb`） |
| 安装命令 | `brew install --cask biedongbin/tap/cpampbar` |
| 文档 | `README.md`（英文主文件）+ `README.zh-CN.md`；`CHANGELOG.md` + `CHANGELOG.zh-CN.md`（Keep a Changelog + SemVer） |
| 版本历史 | v1.0.0 基础版 → v1.1.0 重启/更新/设置 → v1.1.1 菜单扁平化+双语文档 → v1.1.2 应用图标 → v1.2.0 中英双语 |

**git 身份规则（用户规则，最高优先级）**：`~/.claude/rules/git-author-policy.md`
- commit/tag/PR/release 禁止任何非用户本人署名（`Co-Authored-By`、`Signed-off-by`、`🤖 Generated with...` 一律不写）
- 不得擅自改写共享仓库历史（filter-branch/force push 仅当用户当轮明确要求）

## 3. 发布流程（每次发版照此走）

```bash
# 1) 改 Resources/Info.plist 的 CFBundleShortVersionString
# 2) 构建打包
cd ~/workspace/github/cpamp-start-bar && rm -rf build && ./Scripts/build.sh
# 3) 提交 + tag + push（commit message 不带任何署名！）
git add -A && git commit -m "vX.Y.Z: ..." && git tag vX.Y.Z && git push origin main vX.Y.Z
# 4) Release（zip 内根目录直接是 CpampBar.app）
cd build && zip -qry /tmp/CpampBar-X.Y.Z.app.zip CpampBar.app
gh release create vX.Y.Z /tmp/CpampBar-X.Y.Z.app.zip --title "..." --notes "..."
# 5) tap 同步：Casks/cpampbar.rb 改 version + sha256（对 release zip 算 shasum -a 256）
cd ~/workspace/github/homebrew-tap && git add -A && git commit -m "cpampbar X.Y.Z" && git push origin main
```

## 4. 环境全景（本机）

| 组件 | 详情 |
|---|---|
| CPA | Homebrew `cliproxyapi` 8.0.30；配置 `/opt/homebrew/etc/cliproxyapi.conf`；端口 8317；launchd label **`sh.brew.cliproxyapi`**（注意：无 `homebrew.mxcl.` 前缀）；服务命令 `brew services restart cliproxyapi` |
| CPAMP | 原生包 v1.14.7 于 `~/cpamp/cpamp/`；端口 18317；launchd label **`com.seakee.cpa-manager-plus`**（plist 在 `~/Library/LaunchAgents/`，含 WorkingDirectory）；启停用 `launchctl load/unload`，**禁用 `cpa-manager-plusctl`（会抢 SQLite 锁）** |
| 管理密钥 | 双端统一 `admin123456`（CPA conf 里为 bcrypt 哈希，明文即此） |
| ClinePassBridge | v0.3.7 已装于 `~/cpa/plugins/`，CPA conf 有 `plugins:` 块；控制台 `/v0/resource/plugins/clinepassbridge/console` |
| ollama/GLM | conf 的 `openai-compatibility:` 块：GLM 官方（bigmodel）+ Ollama Cloud（`https://ollama.com/v1`，别名加 `olm-` 前缀）；客户端 key `sk-wYrbJmuvwPrBmTEBd` / `biedb_001` / `biedb_002` |

### 关键坑（血泪史，别再踩）

1. **brew 的 launchd plist 无 WorkingDirectory** → 插件注册 `mkdir plugins: read-only file system` 失败。已手动注入 `WorkingDirectory: /Users/biedongbin/cpa`；但 `brew services stop/start` 会重新生成 plist 冲掉修改——插件失注册时先查这个。
2. **本地 tap 有两份**：工作目录 `~/workspace/github/homebrew-tap` 与 brew 实际读取的 `/opt/homebrew/Library/Taps/biedongbin/homebrew-tap`。改完 tap 必须 `cd /opt/homebrew/Library/Taps/biedongbin/homebrew-tap && git pull` 才生效。
3. **cask 的 `postflight` 已弃用**：正确写法是 Homebrew 7 声明式 DSL（`command` 是位置参数、路径用模板 token）：
   ```ruby
   postflight_steps do
     run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/CpampBar.app"]
   end
   ```
4. **GitHub 网络间歇抖动**：git push / curl 下载偶发 `SSL_ERROR_SYSCALL`，重试 2-3 次即可，不是配置问题。
5. **app 图标**：应用图标在 `Resources/AppIcon.icns`（iconset 由 `app-icon.svg` 生成，`iconutil -c icns`）；菜单栏图标 `icon-style-*.png`；CPAMP 官方 logo 源在其仓库 `apps/web/src/assets/brand/`。
6. **CPAMP 升级后**若日志出现 `deferring index ... cleanup-derived`：停服 → `cd ~/cpamp/cpamp && ./cpa-manager-plus cleanup-derived` → 启服。
7. **用户手动测试安装流程**：用户会自己清空本地再 `brew install` 走完整链路——这是刻意行为，不要代劳。

## 5. 当前状态（截至交接）

- [x] v1.2.0 已发布，tap sha256 已同步（`85af02f7...`）
- [x] postflight_steps 迁移完成，deprecated 警告已消除，隔离自动解除实测通过
- [x] 本地 CpampBar 安装已**全部清空**（brew cask、tap、app、登录项、偏好）——用户要自己开终端跑 `brew install --cask biedongbin/tap/cpampbar` 验证
- [ ] 待办（用户提过未做）：CPA conf 的 `usage-statistics-enabled: false` 仍关着，CPAMP 请求监控/成本分析无数据；开了需重启 CPA
- [ ] 用户改名 chuming 一事已放弃（org 被占）

## 6. 目录结构

```
~/workspace/github/cpamp-start-bar/     # 主项目（cpampstartbar 是它的 symlink）
├── Sources/CpampBar.swift              # 全部逻辑（双语、更新、重启、图标切换）
├── Resources/
│   ├── Info.plist                      # 版本号在这里（CFBundleShortVersionString）
│   ├── AppIcon.icns / app-icon.svg     # 应用图标
│   ├── icon-style-line*.png            # 菜单栏线条图标（template）
│   ├── icon-style-color*.png           # 菜单栏彩色图标
│   └── icon-menubar-line.svg           # 线条图标矢量源
├── Scripts/build.sh                    # swiftc → .app → ad-hoc 签名
├── README.md / README.zh-CN.md
├── CHANGELOG.md / CHANGELOG.zh-CN.md
├── HANDOFF.md                          # 本文档
└── build/                              # 构建产物（gitignore）
~/workspace/github/homebrew-tap/        # tap 仓库
└── Casks/cpampbar.rb                   # cask 配方（version/sha256/postflight_steps）
```

## 7. 用户偏好速记

- 沟通语言：中文
- 喜欢直接执行，重大不可逆操作要确认
- 文档风格参照 `biedongbin/dsh-claude-compat`（徽章头 + 双语互链 + Keep a Changelog）
- 本机 Apple Silicon（arm64），macOS 26（Darwin 25.3.0），swiftc 6.3.3，Homebrew 7（清华镜像）
- 会自己开终端验证安装流程
