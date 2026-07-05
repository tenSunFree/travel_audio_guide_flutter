#!/usr/bin/env bash
# scripts/check.sh
# Local CI check script, simulating the GitHub Actions CI process
# Usage: bash scripts/check.sh

set -euo pipefail
cd "$(dirname "$0")/.."

run_step() {
    local name="$1"
    shift
    echo ""
    echo "==> $name"
    "$@"
    echo "Passed: $name"
}

run_step "flutter pub get" flutter pub get

echo ""
echo "==> dart format check"
if dart format --output=none --set-exit-if-changed lib test pigeons; then
    echo "Passed: dart format check"
else
    echo ""
    echo "An unformatted file was found. Please execute:"
    echo "dart format lib test pigeons"
    echo "Then re-git add and commit, and then push again."
    exit 1
fi

run_step "flutter analyze" flutter analyze
run_step "flutter test"    flutter test --reporter compact

# This project sets two flavors in android/app/build.gradle.kts: staging and production.
# Therefore, you cannot directly run `flutter build apk --debug` without the `--flavor` option.
# Otherwise, Gradle will produce app-staging-debug.apk and app-production-debug.apk.
# Flutter tools will report an error if app-debug.apk is not found in the expected path:
# "Gradle build failed to produce an .apk file."
#
# Local pre-push only builds staging (daily development environment), thereby achieving faster inspection speed;
# The complete build and verification of production flavors is handled by .github/workflows/ci.yml after push;
# The two do not replace each other, they just have different functions.
run_step "flutter build staging debug apk" flutter build apk --debug --flavor staging -t lib/main_staging.dart

echo ""
echo "All checks passed!"