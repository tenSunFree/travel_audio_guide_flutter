#!/usr/bin/env bash
# scripts/secret-scan.sh
#
# Performs a complete confidential information scan of the entire working directory and git history.
# Slower than a pre-commit staged-only scan, but more comprehensive.
#
# Recommended usage times:
#   - Before opening a PR
#   - Before release
#   - After major changes
#   - When you suspect you've previously committed a secret
#
# It is not recommended to run this step on every commit (it's too slow). Staged scan can be handled by pre-commit.
#
# Usage: bash scripts/secret-scan.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if ! command -v gitleaks >/dev/null 2>&1; then
    echo ""
    echo "gitleaks not found, unable to perform a full scan."
    echo "Installation method:"
    echo "  macOS         : brew install gitleaks"
    echo "  Windows Scoop : scoop install gitleaks"
    echo "  Windows winget: winget install gitleaks"
    echo "  Other         : https://github.com/gitleaks/gitleaks#installing"
    exit 1
fi

echo ""
echo "==> gitleaks detect (working directory + git history)"

if gitleaks detect --source . --verbose; then
    echo ""
    echo "Passed: No classified information detected"
else
    STATUS=$?
    echo ""
    echo "gitleaks detected potentially confidential information (exit code: $STATUS)"
    echo "If it is confirmed to be a false positive, you can create a .gitleaks.toml file to set the allowlist:"
    echo "https://github.com/gitleaks/gitleaks#configuration"
    exit 1
fi
