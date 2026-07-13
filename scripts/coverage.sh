#!/usr/bin/env bash
# scripts/coverage.sh
# Generate Flutter test coverage report locally, matching the same exclusions
# used by codecov.yml so local numbers line up with the Codecov dashboard.
# Usage: bash scripts/coverage.sh

set -euo pipefail
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

run_step() {
    local name="$1"
    shift
    echo ""
    echo "==> $name"
    "$@"
    echo "Passed: $name"
}

run_step "flutter pub get" $FLUTTER_CMD pub get
run_step "flutter test with coverage" $FLUTTER_CMD test --coverage

echo ""
echo "Coverage file generated: coverage/lcov.info"

if command -v lcov >/dev/null 2>&1; then
    echo ""
    echo "==> filtering out generated files (matches codecov.yml ignore list)"
    lcov --remove coverage/lcov.info \
        '**/*.g.dart' \
        '**/*.freezed.dart' \
        'lib/config/firebase/**' \
        --output-file coverage/lcov.info \
        --ignore-errors unused
    echo "Passed: filtering out generated files"
else
    echo ""
    echo "lcov not found — skipping filter. Local report will include generated files."
    echo "(Codecov's report will still be filtered correctly via codecov.yml.)"
fi

if command -v genhtml >/dev/null 2>&1; then
    echo ""
    echo "==> genhtml coverage/lcov.info"
    genhtml coverage/lcov.info -o coverage/html
    echo "HTML report: coverage/html/index.html"
else
    echo ""
    echo "genhtml not found — skipping HTML report. You can still upload lcov.info to Codecov."
fi

echo ""
echo "Done."