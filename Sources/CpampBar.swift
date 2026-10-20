// CpampBar — CPAMP 菜单栏状态图标
// 编译：./Scripts/build.sh
// 功能：轮询 CPAMP :18317 /health；健康=彩色图标，异常=图标变灰禁用态；
//       菜单提供打开面板 / 重启服务 / 看日志 / 退出。图标取自 CPAMP 官方 logo。
import Cocoa

let cpampURL = "http://127.0.0.1:18317/management.html"
let cpaURL = "http://127.0.0.1:8317/management.html"
let healthURL = "http://127.0.0.1:18317/health"
let launchdLabel = "com.seakee.cpa-manager-plus"
let logPath = ("~/cpamp/cpamp/logs/launchd.err.log" as NSString).expandingTildeInPath

func run(_ cmd: String, _ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: cmd)
    p.arguments = args
    try? p.run()
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var stateItem: NSMenuItem!
    var timer: Timer?

    func applicationDidFinishLaunching(_ note: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = Bundle.main.image(forResource: "icon-menubar")
        statusItem.button?.imageScaling = .scaleProportionallyUpOrDown

        let menu = NSMenu()
        stateItem = menu.addItem(withTitle: "检测中…", action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "打开 CPAMP 面板", action: #selector(openCpamp), keyEquivalent: "1").target = self
        menu.addItem(withTitle: "打开 CPA 面板", action: #selector(openCpa), keyEquivalent: "2").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "重启 CPAMP", action: #selector(restartCpamp), keyEquivalent: "r").target = self
        menu.addItem(withTitle: "查看日志", action: #selector(openLog), keyEquivalent: "l").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出菜单栏（服务继续运行）", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu

        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        let ok = healthOK()
        statusItem.button?.appearsDisabled = !ok   // 异常时图标呈禁用灰色
        statusItem.button?.toolTip = ok ? "CPAMP 运行中 (:18317)" : "CPAMP 无响应 (:18317)"
        stateItem.title = ok ? "CPAMP 运行中 · :18317" : "CPAMP 无响应 · :18317"
    }

    @objc func openCpamp() { run("/usr/bin/open", [cpampURL]) }
    @objc func openCpa() { run("/usr/bin/open", [cpaURL]) }
    @objc func openLog() { run("/usr/bin/open", ["-a", "Console", logPath]) }
    @objc func restartCpamp() {
        run("/bin/launchctl", ["kickstart", "-k", "gui/\(getuid())/\(launchdLabel)"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.refresh() }
    }
    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // 不占 Dock
app.run()
