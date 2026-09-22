# AppleApp — 免签名 IPA 构建

一个原生 SwiftUI 最小工程，用于产出**未签名**的 IPA，全程不需要 Apple Developer 账号或证书。

> 注意：未签名 IPA 无法直接安装到普通 iPhone。它适用于越狱设备、二次重签（AltStore / Sideloadly / 爱思助手等），或后续接入正式签名流程。

## 目录结构

- `AppleApp/` — SwiftUI 源码
- `project.yml` — XcodeGen 配置，用于生成 `.xcodeproj`（不要手改生成的工程）
- `scripts/build_ipa.sh` — Mac 本地一键构建脚本
- `.github/workflows/build-ipa.yml` — GitHub Actions 云端构建

## 方式一：GitHub Actions（Windows 上也能用）

1. 在 GitHub 新建一个空仓库（不要勾选生成 README）。
2. 关联并推送：

   ```bash
   git remote add origin https://github.com/<你的用户名>/<仓库名>.git
   git push -u origin main
   ```

3. 推送后 Actions 自动运行；完成后打开仓库的 **Actions → 该次运行 → Summary**，下载 `AppleApp-unsigned-ipa` 压缩包。

也可以在仓库页面的 **Actions** 标签里手动点击 **Run workflow** 重新触发。

## 方式二：Mac 本地构建

```bash
./scripts/build_ipa.sh
```

产物为仓库根目录下的 `AppleApp-unsigned.ipa`。
