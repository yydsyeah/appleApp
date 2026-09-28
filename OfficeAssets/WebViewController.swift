import UIKit
import WebKit
import UniformTypeIdentifiers

/// 加载系统页面：支持 Excel 导入（文件选择）、导出下载（存到"文件"App）
class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate,
                         WKDownloadDelegate, UIDocumentPickerDelegate {

    private var webView: WKWebView!
    private let progress = UIProgressView(progressViewStyle: .bar)
    private var observation: NSKeyValueObservation?
    private var panelCompletion: (([URL]?) -> Void)?
    private var errorView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "办公用品管理"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh, target: self, action: #selector(reload))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "设置", style: .plain, target: self, action: #selector(openSetup))

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        progress.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addSubview(progress)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progress.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progress.heightAnchor.constraint(equalToConstant: 2),
        ])

        observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
            self?.progress.progress = Float(wv.estimatedProgress)
        }
        load()
    }

    @objc private func load() {
        guard let url = AppSettings.homeURL else { return }
        hideError()
        webView.load(URLRequest(url: url))
    }

    @objc private func reload() {
        if webView.url == nil {
            load()
        } else {
            hideError()
            webView.reload()
        }
    }

    @objc private func openSetup() {
        navigationController?.setViewControllers([SetupViewController()], animated: true)
    }

    // MARK: - 导航错误
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        showError()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        showError()
    }

    // MARK: - 文件上传（Excel 导入）
    // 注意：这个回调在 iOS 上从 18.4 才开始提供（苹果文档确认）。
    // 低于 18.4 的系统（例如本机要装的 iOS 17）由 WebKit 自己弹出文件选择器，
    // 所以这里加 @available 即可，不影响旧系统选文件。
    @available(iOS 18.4, *)
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        panelCompletion = completionHandler
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = parameters.allowsMultipleSelection
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        panelCompletion?(urls)
        panelCompletion = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        panelCompletion?(nil)
        panelCompletion = nil
    }

    // MARK: - 下载（导出 Excel / 下载模板）
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let mime = (navigationResponse.response.mimeType ?? "").lowercased()
        let disposition = (navigationResponse.response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Disposition")?.lowercased() ?? ""
        let isDownload = disposition.contains("attachment")
            || mime.contains("officedocument")
            || mime.contains("octet-stream")
            || mime.contains("ms-excel")
            || mime.contains("zip")
        if #available(iOS 14.5, *), isDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = dir.appendingPathComponent(suggestedFilename)
        try? FileManager.default.removeItem(at: dest)
        completionHandler(dest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        let alert = UIAlertController(
            title: "下载完成",
            message: "文件已保存到「文件」App → 我的 iPhone → 办公用品管理。",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let alert = UIAlertController(title: "下载失败", message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 错误页
    private func showError() {
        hideError()
        let box = UIView()
        box.backgroundColor = .systemBackground
        box.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "无法连接到服务器"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center

        let desc = UILabel()
        desc.text = "请检查：\n1. 手机是否连接公司 WiFi\n2. 公司电脑上的系统是否正在运行\n3. 服务器地址是否正确\n\n当前地址：" + AppSettings.server
        desc.numberOfLines = 0
        desc.font = .systemFont(ofSize: 14)
        desc.textColor = .secondaryLabel

        var c1 = UIButton.Configuration.filled()
        c1.title = "重试连接"
        let retry = UIButton(configuration: c1)
        retry.addTarget(self, action: #selector(reload), for: .touchUpInside)

        var c2 = UIButton.Configuration.gray()
        c2.title = "修改服务器地址"
        let change = UIButton(configuration: c2)
        change.addTarget(self, action: #selector(openSetup), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, desc, retry, change])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stack)
        view.addSubview(box)

        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            box.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            box.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            retry.heightAnchor.constraint(equalToConstant: 46),
            change.heightAnchor.constraint(equalToConstant: 46),
        ])
        errorView = box
    }

    private func hideError() {
        errorView?.removeFromSuperview()
        errorView = nil
    }
}
