#!/bin/bash
# scripts/build_release.sh
#
# Release APK build script (macOS / Linux)
# Usage: bash scripts/build_release.sh
# # CI/CD environment: Use --dart-define to directly inject secrets (see cd.yml instructions)

set -e
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

ENV_FILE="env/release.json"

if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "找不到 $ENV_FILE"
  echo ""
  echo "請照以下步驟建立："
  echo "  1. cp env/example.json env/release.json"
  echo "  2. 填入正式環境的 SENTRY_DSN，並將 APP_ENV 改為 production"
  echo ""
  exit 1
fi

echo ""
echo "Building release APK..."
echo "    env file : $ENV_FILE"
echo ""

$FLUTTER_CMD build apk --release \
  --dart-define-from-file="$ENV_FILE"

echo ""
echo "Build 完成"
echo "    輸出：build/app/outputs/flutter-apk/app-release.apk"
echo ""