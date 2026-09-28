import UIKit

/// 首次使用：填写服务器地址
class SetupViewController: UIViewController {

    private let field = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "办公用品管理"
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "办公用品管理系统"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center

        let desc = UILabel()
        desc.text = "首次使用请填写服务器地址（公司里运行系统的那台电脑），例如 192.168.110.24。\n\n手机需要连接公司 WiFi。"
        desc.font = .systemFont(ofSize: 15)
        desc.textColor = .secondaryLabel
        desc.numberOfLines = 0

        field.placeholder = "192.168.110.24 或 192.168.110.24:8080"
        field.borderStyle = .roundedRect
        field.keyboardType = .URL
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.text = AppSettings.server.isEmpty ? "192.168.110.24" : AppSettings.server

        var config = UIButton.Configuration.filled()
        config.title = "保存并连接"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(connect), for: .touchUpInside)

        let tip = UILabel()
        tip.text = "提示：进入系统后，右上角「设置」可随时修改服务器地址。"
        tip.font = .systemFont(ofSize: 12)
        tip.textColor = .tertiaryLabel
        tip.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, desc, field, button, tip])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    @objc private func connect() {
        let host = AppSettings.normalize(field.text ?? "")
        if host.isEmpty {
            let alert = UIAlertController(title: "提示", message: "请填写服务器地址", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
            return
        }
        AppSettings.server = host
        navigationController?.setViewControllers([WebViewController()], animated: true)
    }
}
