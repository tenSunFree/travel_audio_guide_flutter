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

# ------------------------------------------------------------
# Generate the HTML report.
# Prefers genhtml (from lcov) if installed; otherwise falls back to
# @lcov-viewer/cli (npm, no admin/Perl required) if available.
# Set NO_OPEN=1 to skip auto-opening the browser afterwards.
# ------------------------------------------------------------
REPORT_PATH="$(pwd)/coverage/html/index.html"

if command -v genhtml >/dev/null 2>&1; then
  genhtml coverage/lcov.info -o coverage/html
  echo "HTML report: $REPORT_PATH"
elif command -v lcov-viewer >/dev/null 2>&1; then
  lcov-viewer lcov -o coverage/html coverage/lcov.info
  echo "HTML report: $REPORT_PATH"
else
  echo ""
  echo "Neither genhtml nor lcov-viewer are installed; HTML report generation will be skipped."
  echo "Choose one to install:"
  echo "  1) genhtml (lcov package, requires system administrator privileges):"
  echo "       Windows (choco, admin required): choco install lcov -y"
  echo "       macOS                     : brew install lcov"
  echo "       Ubuntu/Debian             : sudo apt-get install lcov"
  echo "  2) lcov-viewer (npm, no system administrator privileges required):"
  echo "       npm install -g @lcov-viewer/cli"
  exit 0
fi

if [[ "${NO_OPEN:-0}" != "1" ]]; then
  echo ""
  echo "==> opening report in default browser"

  if command -v open >/dev/null 2>&1; then
    # macOS
    open "$REPORT_PATH"
  elif command -v xdg-open >/dev/null 2>&1; then
    # Linux (desktop) / most WSL setups with a browser bridge configured
    xdg-open "$REPORT_PATH" >/dev/null 2>&1 &
  elif command -v wslview >/dev/null 2>&1; then
    # WSL, if wslu is installed (sudo apt install wslu)
    wslview "$REPORT_PATH"
  elif [[ "${OS:-}" == "Windows_NT" ]] || command -v cmd.exe >/dev/null 2>&1; then
    # Git Bash / WSL fallback via Windows explorer
    cmd.exe /c start "" "$(wslpath -w "$REPORT_PATH" 2>/dev/null || echo "$REPORT_PATH")" >/dev/null 2>&1 || true
  else
    echo "No available enable command found. Please enable manually: $REPORT_PATH"
  fi
fi