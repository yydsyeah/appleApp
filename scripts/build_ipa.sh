#!/usr/bin/env bash
# 构建免签名 IPA。需要在 macOS 上运行（Xcode + Homebrew）。
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild 未找到，请先安装 Xcode。" >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "==> 安装 XcodeGen"
  brew install xcodegen
fi

echo "==> 生成 Xcode 工程"
xcodegen generate

echo "==> 编译免签名 Release（真机 arm64）"
xcodebuild \
  -project AppleApp.xcodeproj \
  -scheme AppleApp \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  build

APP="build/DerivedData/Build/Products/Release-iphoneos/AppleApp.app"
if [[ ! -d "$APP" ]]; then
  echo "未找到编译产物：$APP" >&2
  exit 1
fi

echo "==> 打包 IPA"
rm -rf dist/Payload
mkdir -p dist/Payload
cp -R "$APP" dist/Payload/
rm -f AppleApp-unsigned.ipa
( cd dist && zip -ryq ../AppleApp-unsigned.ipa Payload )

echo "完成：AppleApp-unsigned.ipa"
ls -lh AppleApp-unsigned.ipa
