#!/bin/bash
# 构建并打包 CpampBar.app
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
BUILD="$ROOT/build"
APP="$BUILD/CpampBar.app"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "[1/4] 编译 Swift…"
swiftc -O -o "$APP/Contents/MacOS/CpampBar" Sources/CpampBar.swift

echo "[2/4] 拷贝资源…"
cp Resources/icon-style-*.png "$APP/Contents/Resources/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp Resources/Info.plist "$APP/Contents/"

echo "[3/4] ad-hoc 签名…"
codesign --force --sign - "$APP"

echo "[4/4] 完成：$APP"
echo "运行: open $APP"
