#!/bin/bash
# ============================================================
# setup-hooks.sh
# One-click installation of project git hooks (pre-commit + pre-push)
# Usage: bash scripts/setup-hooks.sh
# ============================================================

set -e
cd "$(git rev-parse --show-toplevel)"

HOOKS_DIR=".git/hooks"

install_hook() {
    local name="$1"
    cp "scripts/$name" "$HOOKS_DIR/$name"
    chmod +x "$HOOKS_DIR/$name"
    echo "Installed: $HOOKS_DIR/$name"
}

install_hook "pre-commit"
install_hook "pre-push"

echo ""
echo "Git hooks installation complete!"
echo "  - pre-commit: dart format(staged) + secret scan(staged)"
echo "  - pre-push:   scripts/check.sh (pub get + format + analyze + test + build)"