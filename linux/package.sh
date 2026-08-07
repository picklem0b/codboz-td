#!/usr/bin/env bash
# ============================================================
# COD Tower Defense — build the Linux distribution zip
#
# Creates codboz-td-linux.zip in the repo root containing the
# game (index.html, lobby, music) plus the linux/ launcher
# so you can copy it to a Linux laptop and run ./install.sh.
#
# Usage:  ./package.sh
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/codboz-td-linux.zip"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/codboz-td/linux"

echo "COD Tower Defense — packaging Linux version..."

cp -f "$ROOT/index.html" "$STAGE/codboz-td/"
cp -rf "$ROOT/MENU UI" "$STAGE/codboz-td/" 2>/dev/null || echo "  (warn: MENU UI missing)"
cp -rf "$ROOT/Intro music" "$STAGE/codboz-td/" 2>/dev/null || echo "  (warn: Intro music missing)"
cp -rf "$ROOT/Background music" "$STAGE/codboz-td/" 2>/dev/null || echo "  (warn: Background music missing)"
cp -f "$ROOT/play.py" "$STAGE/codboz-td/" 2>/dev/null || true
cp -f "$ROOT/linux/codboz-td" "$ROOT/linux/install.sh" "$ROOT/linux/uninstall.sh" "$ROOT/linux/codboz-td.desktop" "$ROOT/linux/icon.svg" "$ROOT/linux/package.sh" "$STAGE/codboz-td/linux/"

cat > "$STAGE/codboz-td/README.txt" <<'EOF'
COD TOWER DEFENSE — LINUX
=========================

Requirements:  python3, a web browser (Firefox/Chromium/Chrome)

Quick start:
  1) cd codboz-td
  2) ./linux/install.sh      (installs to ~/.local + app menu)
  3) codboz-td               (launches the game in your browser)

Or run without installing:
  cd codboz-td && ./linux/codboz-td

Controls (desktop):
  - 1-9        select build card       - Enter / Space  start round
  - left click place / select tower    - Esc  pause / cancel / close
  - right click cancel build           - G    cycle player gun
  - WASD / arrows: Dead Ops movement   - hold left click: shoot
EOF

chmod +x "$STAGE/codboz-td/linux/codboz-td" "$STAGE/codboz-td/linux/install.sh" "$STAGE/codboz-td/linux/uninstall.sh" "$STAGE/codboz-td/linux/package.sh"

# zip with Python (no external zip needed)
python3 - "$OUT" "$STAGE" <<'PYEOF'
import os, sys, zipfile
out, stage = sys.argv[1], sys.argv[2]
src = os.path.join(stage, 'codboz-td')
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        for f in files:
            full = os.path.join(root, f)
            rel = os.path.relpath(full, stage)
            z.write(full, rel)
print('zip written')
PYEOF
echo "Built: $OUT"
ls -lh "$OUT"
