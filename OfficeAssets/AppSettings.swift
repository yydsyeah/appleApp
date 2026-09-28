import Foundation

/// 服务器地址保存/规范化
struct AppSettings {
    private static let key = "oms_server"

    static var server: String {
        get { UserDefaults.standard.string(forKey: key) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    /// 把用户输入规范化成 http://host[:port] 形式
    static func normalize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return "" }
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") {
            s = "http://" + s
        }
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }

    static var homeURL: URL? {
        let base = server
        guard !base.isEmpty else { return nil }
        return URL(string: base + "/oms")
    }
}
