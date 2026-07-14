#!/usr/bin/env bash
# scripts/coverage.sh
# Generates the raw Flutter LCOV report locally.
# Exclusions are maintained solely in codecov.yml — this script no longer
# filters the report, to avoid two divergent sources of truth.
# Usage: bash scripts/coverage.sh

set -euo pipefail
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

echo ""
echo "==> flutter pub get"
$FLUTTER_CMD pub get

echo ""
echo "==> flutter test --coverage"
$FLUTTER_CMD test --coverage

if [[ ! -s coverage/lcov.info ]]; then
  echo "ERROR: coverage/lcov.info was not generated or is empty."
  exit 1
fi

source_count=$(grep -c '^SF:' coverage/lcov.info || true)
echo ""
echo "Coverage report generated: coverage/lcov.info ($source_count source files)"
echo "Note: generated files (.g.dart / .freezed.dart / firebase_options_*) are"
echo "excluded on Codecov via codecov.yml, not filtered locally."

if command -v genhtml >/dev/null 2>&1; then
  genhtml coverage/lcov.info -o coverage/html
  echo "HTML report: coverage/html/index.html"
fi