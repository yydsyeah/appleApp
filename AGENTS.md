# AppleApp 构建约定（供 Codex 使用）

- 目标产物：免签名 IPA（`AppleApp-unsigned.ipa`），全程不使用 Apple 账号或证书。
- iOS 编译只能由 macOS 上的 `xcodebuild` 完成；本机是 Windows 时统一走 GitHub Actions（`.github/workflows/build-ipa.yml`）。
- Xcode 工程由 XcodeGen 从 `project.yml` 生成，不要直接修改 `AppleApp.xcodeproj`。
- 本地 Mac 构建命令：`./scripts/build_ipa.sh`。
- 云端构建：推送到 `main` 分支自动触发；产物在 Actions 运行页的 Summary 中以 artifact 形式下载。
- 签名已被显式禁用：`CODE_SIGNING_ALLOWED=NO`。如后续要上架/真机安装，需另行配置签名与证书。
- 新增 Swift 源文件时放入 `AppleApp/` 目录即可（`project.yml` 已包含整个目录）。
