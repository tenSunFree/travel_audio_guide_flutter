#!/bin/bash
# ============================================================
# release.sh
# Native Release APK build script
# Will run check.sh to ensure quality before packaging
# Usage: ./scripts/release.sh
# ============================================================

set -e
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

run_step() {
    local name="$1"
    shift
    echo ""
    echo "▶  $name"
    "$@"
    echo "✅ Passed: $name"
}

run_step "CI checks"                   bash scripts/check.sh
run_step "flutter build apk --release" $FLUTTER_CMD build apk --release

echo ""
echo "Release APK built successfully!"
echo "build/app/outputs/flutter-apk/app-release.apk"