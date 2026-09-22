# AppleApp — 俄罗斯方块（免签名 IPA 构建）

一个原生 SwiftUI 俄罗斯方块小游戏 Demo，用于产出**未签名**的 IPA，全程不需要 Apple Developer 账号或证书。

## 玩法

- 点击棋盘：旋转方块；左右滑动：移动；下滑：软降；上滑：落底
- 底部按钮提供：暂存、旋转、软降、落底、左移、右移、暂停、重开
- 支持 7-bag 随机器、幽灵投影、消行计分与逐级加速
- 内置 8-bit 风格音效与循环背景音乐，右上角可一键静音（设置会被记住）

> 注意：未签名 IPA 无法直接安装到普通 iPhone。它适用于越狱设备、二次重签（AltStore / Sideloadly / 爱思助手等），或后续接入正式签名流程。

## 目录结构

- `AppleApp/TetrisEngine.swift` — 纯逻辑游戏引擎（不依赖 SwiftUI）
- `AppleApp/TetrisGameView.swift` — 游戏界面与交互
- `AppleApp/TetrisSound.swift` — 音效与背景音乐播放
- `AppleApp/Sounds/` — 打包进 App 的 WAV 音效（由脚本生成）
- `scripts/generate_sounds.py` — 重新生成音效/音乐的脚本
- `AppleApp/` — 其余 SwiftUI 源码
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
