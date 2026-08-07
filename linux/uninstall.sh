#!/usr/bin/env bash
# ============================================================
# COD Tower Defense — uninstaller
# Usage:  ./uninstall.sh
# ============================================================
set -euo pipefail

BIN="$HOME/.local/bin/codboz-td"
APPS="$HOME/.local/share/applications/codboz-td.desktop"
ICON="$HOME/.local/share/icons/hicolor/scalable/apps/codboz-td.svg"

rm -f "$BIN" "$APPS" "$ICON"
if [ -d "$HOME/.local/share/codboz-td" ]; then
  rm -rf "$HOME/.local/share/codboz-td"
fi
echo "COD Tower Defense uninstalled."
