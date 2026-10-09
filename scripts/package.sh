#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> 生成工程"
xcodegen generate

echo "==> Release 构建"
xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox \
  -configuration Release -destination 'platform=macOS' \
  CONFIGURATION_BUILD_DIR="$(pwd)/build" build 2>&1 | tail -3

echo "==> Ad-hoc 签名"
codesign --force --deep --sign - build/DevToolbox.app
codesign --verify build/DevToolbox.app

echo "==> 压缩"
rm -f DevToolbox.zip
ditto -c -k --keepParent build/DevToolbox.app DevToolbox.zip

echo "==> 完成：$(pwd)/DevToolbox.zip"
