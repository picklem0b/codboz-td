#!/usr/bin/env bash
# ============================================================
# COD Tower Defense — Linux installer
#
# Copies the game to ~/.local/share/codboz-td, installs the
# launcher to ~/.local/bin, and adds a desktop entry + icon
# so the game appears in your application menu.
#
# Usage:  ./install.sh
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.local/share/codboz-td"
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"

echo "COD Tower Defense installer"
echo "  game  -> $DEST"
echo "  bin   -> $BIN/codboz-td"
echo "  menu  -> $APPS/codboz-td.desktop"
echo "  icon  -> $ICONS/codboz-td.svg"

mkdir -p "$DEST" "$BIN" "$APPS" "$ICONS"

# game files needed at runtime (index.html + lobby + music)
cp -f "$ROOT/index.html" "$DEST/"
cp -rf "$ROOT/MENU UI" "$DEST/" 2>/dev/null || true
cp -rf "$ROOT/Intro music" "$DEST/" 2>/dev/null || true
cp -rf "$ROOT/Background music" "$DEST/" 2>/dev/null || true
cp -f "$ROOT/play.py" "$DEST/" 2>/dev/null || true

# launcher
install -m755 "$ROOT/linux/codboz-td" "$BIN/codboz-td"

# desktop entry (point Exec at the real binary path)
sed "s|^Exec=codboz-td|Exec=$BIN/codboz-td|" "$ROOT/linux/codboz-td.desktop" > "$APPS/codboz-td.desktop"

# icon
cp -f "$ROOT/linux/icon.svg" "$ICONS/codboz-td.svg"

# refresh the app menu (best-effort; not fatal if missing)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true

echo
echo "Installed. Launch it with:"
echo "    codboz-td"
echo "or from your application menu (look for 'COD Tower Defense')."
echo
echo "Uninstall with:  $ROOT/linux/uninstall.sh"
