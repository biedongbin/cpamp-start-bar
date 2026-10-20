// CpampBar — CPAMP 菜单栏管家
// 编译：./Scripts/build.sh
// 功能：
//   · 轮询 CPAMP :18317 /health，图标反映健康态
//   · 重启 CPA 内核 / 重启 CPAMP / 重启两者（launchctl kickstart）
//   · 一键 Update CPA（brew upgrade + 重启）/ 一键 Update CPAMP（下载 release 替换二进制）
//   · 开机自启（SMAppService）、菜单栏图标四选（线条/彩色/圆点/自定义 PNG）
//   · 中/英文界面切换（即时生效）
//   · 打开双面板、看日志、退出
import Cocoa
import ServiceManagement

// MARK: - 常量（按需改这里）
let cpampPanel = "http://127.0.0.1:18317/management.html"
let cpaPanel = "http://127.0.0.1:8317/management.html"
let healthURL = "http://127.0.0.1:18317/health"
let cpaLabel = "sh.brew.cliproxyapi"                    // brew 服务 label
let cpampLabel = "com.seakee.cpa-manager-plus"          // CPAMP LaunchAgent label
let cpampPlist = ("~/Library/LaunchAgents/" + cpampLabel + ".plist") as NSString
let cpampDir = ("~/cpamp/cpamp" as NSString).expandingTildeInPath
let logPath = ("~/cpamp/cpamp/logs/launchd.err.log" as NSString).expandingTildeInPath
let cpampReleaseAPI = "https://api.github.com/repos/seakee/CPA-Manager-Plus/releases/latest"
let brewBin = "/opt/homebrew/bin/brew"

// MARK: - 语言
enum Lang: String {
    case zh, en
}

let langKey = "MenuBarLanguage"

func currentLang() -> Lang {
    Lang(rawValue: UserDefaults.standard.string(forKey: langKey) ?? "") ?? .zh
}

/// 双语取值：L("中文", "English")
func L(_ zh: String, _ en: String) -> String {
    currentLang() == .zh ? zh : en
}

// MARK: - 工具
func run(_ cmd: String, _ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: cmd)
    p.arguments = args
    try? p.run()
}

@discardableResult
func shell(_ cmd: String, _ args: [String]) -> (code: Int32, out: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: cmd)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do {
        try p.run()
    } catch {
        return (-1, "\(error)")
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

func healthOK() -> Bool {
    guard let url = URL(string: healthURL) else { return false }
    var req = URLRequest(url: url)
    req.timeoutInterval = 3
    let sem = DispatchSemaphore(value: 0)
    var ok = false
    URLSession.shared.dataTask(with: req) { data, _, _ in
        if let d = data, let s = String(data: d, encoding: .utf8) { ok = s.contains("\"ok\":true") }
        sem.signal()
    }.resume()
    _ = sem.wait(timeout: .now() + 4)
    return ok
}

func notify(_ msg: String) {
    run("/usr/bin/osascript", ["-e", "display notification \"\(msg)\" with title \"CpampBar\""])
}

// MARK: - 图标风格
enum IconStyle: String {
    case line, color, dot, custom

    var label: String {
        switch self {
        case .line: return L("线条版（随主题变色）", "Line-art (theme-adaptive)")
        case .color: return L("彩色 logo", "Color logo")
        case .dot: return L("简约圆点", "Simple dot")
        case .custom: return L("自定义图片", "Custom image")
        }
    }
}

let iconStyleKey = "MenuBarIconStyle"
let customIconPath = ("~/Library/Application Support/CpampBar/custom-icon.png" as NSString).expandingTildeInPath

func dotImage(_ color: NSColor) -> NSImage {
    let img = NSImage(size: NSSize(width: 18, height: 18))
    img.lockFocus()
    color.setFill()
    NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10)).fill()
    img.unlockFocus()
    return img
}

// MARK: - 主类
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var stateItem: NSMenuItem!
    var autostartItem: NSMenuItem!
    var iconStyleItems: [IconStyle: NSMenuItem] = [:]
    var langItems: [Lang: NSMenuItem] = [:]
    var timer: Timer?
    var busy = false

    func applicationDidFinishLaunching(_ note: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        buildMenu()
        applyIcon()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func buildMenu() {
        iconStyleItems.removeAll()
        langItems.removeAll()
        let menu = NSMenu()
        stateItem = menu.addItem(withTitle: L("检测中…", "Checking…"), action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(.separator())

        menu.addItem(withTitle: L("打开 CPAMP 面板", "Open CPAMP Panel"), action: #selector(openCpamp), keyEquivalent: "1").target = self
        menu.addItem(withTitle: L("打开 CPA 面板", "Open CPA Panel"), action: #selector(openCpa), keyEquivalent: "2").target = self
        menu.addItem(.separator())

        // 重启三连
        menu.addItem(withTitle: L("重启 CPA 内核", "Restart CPA Kernel"), action: #selector(restartCpa), keyEquivalent: "").target = self
        menu.addItem(withTitle: L("重启 CPAMP", "Restart CPAMP"), action: #selector(restartCpamp), keyEquivalent: "r").target = self
        menu.addItem(withTitle: L("重启 CPA + CPAMP", "Restart CPA + CPAMP"), action: #selector(restartBoth), keyEquivalent: "").target = self
        menu.addItem(.separator())

        // 一键更新
        menu.addItem(withTitle: L("一键 Update CPA（brew）", "Update CPA (brew)"), action: #selector(updateCpa), keyEquivalent: "").target = self
        menu.addItem(withTitle: L("一键 Update CPAMP（release）", "Update CPAMP (release)"), action: #selector(updateCpamp), keyEquivalent: "").target = self
        menu.addItem(.separator())

        // 开机自启 + 图标 + 语言（顶层直达）
        autostartItem = menu.addItem(withTitle: L("开机自启", "Launch at Login"), action: #selector(toggleAutostart), keyEquivalent: "")
        autostartItem.target = self
        let iconItem = menu.addItem(withTitle: L("菜单栏图标", "Menu Bar Icon"), action: nil, keyEquivalent: "")
        let iconSub = NSMenu()
        for style in [IconStyle.line, .color, .dot, .custom] {
            let it = iconSub.addItem(withTitle: style.label, action: #selector(pickIconStyle(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = style
            iconStyleItems[style] = it
        }
        iconSub.addItem(.separator())
        iconSub.addItem(withTitle: L("从文件选择…", "Choose from File…"), action: #selector(chooseCustomIcon), keyEquivalent: "").target = self
        iconItem.submenu = iconSub

        let langItem = menu.addItem(withTitle: L("语言 / Language", "Language / 语言"), action: nil, keyEquivalent: "")
        let langSub = NSMenu()
        for l in [Lang.zh, .en] {
            let it = langSub.addItem(withTitle: l == .zh ? "简体中文" : "English", action: #selector(pickLang(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = l.rawValue
            langItems[l] = it
        }
        langItem.submenu = langSub
        menu.addItem(.separator())

        menu.addItem(withTitle: L("查看日志", "View Logs"), action: #selector(openLog), keyEquivalent: "l").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: L("退出菜单栏（服务继续运行）", "Quit (services keep running)"), action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    // MARK: 图标
    func applyIcon() {
        let style = IconStyle(rawValue: UserDefaults.standard.string(forKey: iconStyleKey) ?? "") ?? .line
        let button = statusItem.button
        button?.appearsDisabled = false
        switch style {
        case .line:
            let img = Bundle.main.image(forResource: "icon-style-line")
            img?.isTemplate = true
            button?.image = img
            button?.title = ""
        case .color:
            button?.image = Bundle.main.image(forResource: "icon-style-color")
            button?.title = ""
        case .dot:
            button?.image = nil
            button?.title = "●"
            button?.font = NSFont.systemFont(ofSize: 12)
        case .custom:
            if let img = NSImage(contentsOfFile: customIconPath) {
                img.size = NSSize(width: 18, height: 18)
                button?.image = img
                button?.title = ""
            } else {
                button?.image = Bundle.main.image(forResource: "icon-style-line")
                button?.title = ""
            }
        }
    }

    func refresh() {
        let ok = healthOK()
        let style = IconStyle(rawValue: UserDefaults.standard.string(forKey: iconStyleKey) ?? "") ?? .line
        if style == .dot {
            statusItem.button?.contentTintColor = ok ? .systemGreen : .systemRed
            statusItem.button?.appearsDisabled = false
        } else {
            statusItem.button?.appearsDisabled = !ok
        }
        statusItem.button?.toolTip = ok ? L("CPAMP 运行中 (:18317)", "CPAMP running (:18317)")
                                        : L("CPAMP 无响应 (:18317)", "CPAMP not responding (:18317)")
        stateItem.title = ok ? L("CPAMP 运行中 · :18317", "CPAMP running · :18317")
                             : L("CPAMP 无响应 · :18317", "CPAMP not responding · :18317")
        autostartItem?.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        let currentStyle = IconStyle(rawValue: UserDefaults.standard.string(forKey: iconStyleKey) ?? "") ?? .line
        for (style, item) in iconStyleItems { item.state = (style == currentStyle) ? .on : .off }
        let currentLang_ = currentLang()
        for (l, item) in langItems { item.state = (l == currentLang_) ? .on : .off }
    }

    // MARK: 面板
    @objc func openCpamp() { run("/usr/bin/open", [cpampPanel]) }
    @objc func openCpa() { run("/usr/bin/open", [cpaPanel]) }
    @objc func openLog() { run("/usr/bin/open", ["-a", "Console", logPath]) }

    // MARK: 重启
    @objc func restartCpa() {
        run("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(cpaLabel)"])
        stateItem.title = L("已发重启 CPA 指令…", "Restart CPA command sent…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.refresh() }
    }

    @objc func restartCpamp() {
        run("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(cpampLabel)"])
        stateItem.title = L("已发重启 CPAMP 指令…", "Restart CPAMP command sent…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.refresh() }
    }

    @objc func restartBoth() {
        restartCpa()
        restartCpamp()
    }

    // MARK: 更新
    @objc func updateCpa() {
        guard !busy else { return }
        busy = true
        stateItem.title = L("正在更新 CPA（brew upgrade）…", "Updating CPA (brew upgrade)…")
        DispatchQueue.global().async {
            let r = shell(brewBin, ["upgrade", "cliproxyapi"])
            if r.code == 0 { _ = shell("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(cpaLabel)"]) }
            DispatchQueue.main.async {
                self.busy = false
                notify(r.code == 0
                       ? L("CPA 已更新并重启", "CPA updated & restarted")
                       : L("CPA 更新失败：", "CPA update failed: ") + "\(r.out.suffix(120))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.refresh() }
            }
        }
    }

    @objc func updateCpamp() {
        guard !busy else { return }
        busy = true
        stateItem.title = L("正在更新 CPAMP…", "Updating CPAMP…")
        DispatchQueue.global().async {
            let fail = { (msg: String) in
                DispatchQueue.main.async {
                    self.busy = false
                    notify(L("CPAMP 更新失败：", "CPAMP update failed: ") + msg)
                    self.refresh()
                }
            }
            // 1. 最新版本号
            let tagR = shell("/usr/bin/curl", ["-sL", "--max-time", "15", cpampReleaseAPI])
            guard tagR.code == 0 else { return fail(L("无法获取版本", "cannot fetch version")) }
            let body = tagR.out
            guard let r = body.range(of: "\"tag_name\":\""),
                  let v = body[r.upperBound...].range(of: "\"") else { return fail(L("解析版本失败", "cannot parse version")) }
            let tag = String(body[r.upperBound..<v.lowerBound])
            // 2. 下载
            let ver = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            let url = "https://github.com/seakee/CPA-Manager-Plus/releases/download/\(tag)/cpa-manager-plus_\(ver)_darwin_arm64.tar.gz"
            let dl = shell("/usr/bin/curl", ["-sL", "--max-time", "120", "-o", "/tmp/cpamp-update.tar.gz", url])
            guard dl.code == 0, FileManager.default.fileExists(atPath: "/tmp/cpamp-update.tar.gz") else { return fail(L("下载失败", "download failed")) }
            // 3. 解压
            _ = shell("/usr/bin/rm", ["-rf", "/tmp/cpamp-update"])
            _ = shell("/bin/mkdir", ["-p", "/tmp/cpamp-update"])
            let ex = shell("/usr/bin/tar", ["-xzf", "/tmp/cpamp-update.tar.gz", "-C", "/tmp/cpamp-update"])
            guard ex.code == 0 else { return fail(L("解压失败", "extract failed")) }
            // 4. 定位二进制
            let find = shell("/usr/bin/find", ["/tmp/cpamp-update", "-name", "cpa-manager-plus", "-type", "f"])
            guard let bin = find.out.split(separator: "\n").first.map(String.init), !bin.isEmpty else { return fail(L("包内未找到二进制", "binary not found in archive")) }
            // 5. 停服 → 替换 → 起服
            _ = shell("/bin/launchctl", ["unload", cpampPlist as String])
            _ = shell("/bin/cp", ["-f", bin, "\(cpampDir)/cpa-manager-plus"])
            _ = shell("/bin/chmod", ["+x", "\(cpampDir)/cpa-manager-plus"])
            let load = shell("/bin/launchctl", ["load", cpampPlist as String])
            DispatchQueue.main.async {
                self.busy = false
                if load.code == 0 {
                    notify(L("CPAMP 已更新到 \(tag) 并重启", "CPAMP updated to \(tag) & restarted"))
                } else {
                    notify(L("CPAMP 已替换为 \(tag)，但服务启动失败，请查日志", "CPAMP replaced with \(tag), but service failed to start — check logs"))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.refresh() }
            }
        }
    }

    // MARK: 设置
    @objc func toggleAutostart() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                notify(L("已关闭开机自启", "Launch at login disabled"))
            } else {
                try SMAppService.mainApp.register()
                notify(L("已开启开机自启", "Launch at login enabled"))
            }
        } catch {
            notify(L("开机自启设置失败：", "Autostart toggle failed: ") + error.localizedDescription)
        }
        refresh()
    }

    @objc func pickIconStyle(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? IconStyle else { return }
        UserDefaults.standard.set(style.rawValue, forKey: iconStyleKey)
        applyIcon()
        refresh()
    }

    @objc func pickLang(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let l = Lang(rawValue: raw) else { return }
        UserDefaults.standard.set(l.rawValue, forKey: langKey)
        buildMenu()   // 重建菜单即时换语言
        applyIcon()
        refresh()
    }

    @objc func chooseCustomIcon() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.message = L("选择菜单栏图标（建议 36×36 以上透明底 PNG）", "Choose a menu bar icon (transparent PNG, 36×36+ recommended)")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let dir = (customIconPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(atPath: customIconPath)
        do {
            try FileManager.default.copyItem(atPath: url.path, toPath: customIconPath)
            UserDefaults.standard.set(IconStyle.custom.rawValue, forKey: iconStyleKey)
            applyIcon()
            refresh()
        } catch {
            notify(L("图标设置失败：", "Icon setup failed: ") + error.localizedDescription)
        }
    }

    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // 不占 Dock
app.run()
