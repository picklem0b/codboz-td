#!/usr/bin/env bash
# ============================================================
# COD Tower Defense — Linux distribution packager
#
# Creates codboz-td-linux.zip in the repo root containing the
# game (index.html, lobby, music) plus the linux/ launcher
# so you can copy it to a Linux laptop and run ./install.sh.
#
# Usage:
#   ./package.sh
#   ./package.sh --help
#   ./package.sh --verbose
#   ./package.sh --force
# ============================================================

set -euo pipefail

# Configuration
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/codboz-td-linux.zip"

STAGE=""
VERBOSE=0
FORCE=0

PACKAGE_NAME="codboz-td"
PACKAGE_ROOT=""


# Output helpers
info() {
    printf '  \033[1;34m→\033[0m %s\n' "$*"
}

success() {
    printf '  \033[1;32m✓\033[0m %s\n' "$*"
}

warning() {
    printf '  \033[1;33m!\033[0m %s\n' "$*" >&2
}

error() {
    printf '  \033[1;31m✗\033[0m %s\n' "$*" >&2
}

debug() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        printf '  \033[2m[debug] %s\033[0m\n' "$*"
    fi
}

die() {
    error "$*"
    exit 1
}


# Usage
usage() {
    cat <<EOF
COD Tower Defense — Linux distribution packager

Usage:
  $(basename "$0") [OPTIONS]

Options:
  -h, --help      Show this help message
  -v, --verbose   Show additional packaging details
      --force     Replace an existing archive without prompting

Output:
  $OUT
EOF
}


# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;

        -v|--verbose)
            VERBOSE=1
            shift
            ;;

        --force)
            FORCE=1
            shift
            ;;

        *)
            error "Unknown option: $1"
            echo
            usage
            exit 1
            ;;
    esac
done


# Cleanup
cleanup() {
    local status=$?

    if [[ -n "${STAGE:-}" && -d "$STAGE" ]]; then
        debug "Removing temporary staging directory: $STAGE"
        rm -rf "$STAGE"
    fi

    if [[ "$status" -ne 0 ]]; then
        error "Packaging failed."
    fi

    exit "$status"
}

trap cleanup EXIT INT TERM


# Validate environment
info "Checking packaging environment..."

[[ -d "$ROOT" ]] || die "Repository root does not exist: $ROOT"

command -v mkdir >/dev/null 2>&1 || die "'mkdir' is required."
command -v cp >/dev/null 2>&1 || die "'cp' is required."
command -v chmod >/dev/null 2>&1 || die "'chmod' is required."
command -v rm >/dev/null 2>&1 || die "'rm' is required."
command -v python3 >/dev/null 2>&1 || \
    die "Python 3 is required to create the ZIP archive."

success "Packaging tools are available."


# Validate required source files
info "Checking required game files..."

REQUIRED_FILES=(
    "$ROOT/index.html"
    "$ROOT/linux/codboz-td"
    "$ROOT/linux/install.sh"
    "$ROOT/linux/uninstall.sh"
    "$ROOT/linux/codboz-td.desktop"
    "$ROOT/linux/icon.svg"
    "$ROOT/linux/package.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    [[ -f "$file" ]] || die "Required file is missing: $file"
    debug "Found: ${file#"$ROOT"/}"
done

success "Required files are present."


# Check optional game files
info "Checking optional game assets..."

OPTIONAL_DIRS=(
    "MENU UI"
    "Intro music"
    "Background music"
)

OPTIONAL_FILES=(
    "play.py"
)

for dir in "${OPTIONAL_DIRS[@]}"; do
    if [[ -d "$ROOT/$dir" ]]; then
        success "Including: $dir/"
    else
        warning "Optional directory missing: $dir/"
    fi
done

for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        success "Including: $file"
    else
        warning "Optional file missing: $file"
    fi
done


# Handle existing output archive
if [[ -e "$OUT" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
        info "Replacing existing archive..."
        rm -f "$OUT"
        success "Existing archive removed."
    else
        die "Output archive already exists: $OUT
Use --force to replace it."
    fi
fi


# Create staging directory
info "Creating temporary package..."

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/codboz-td-package.XXXXXX")"
PACKAGE_ROOT="$STAGE/$PACKAGE_NAME"

mkdir -p "$PACKAGE_ROOT/linux"

success "Temporary package created."


# Copy game files
info "Copying game files..."

# Required game file.
cp -f \
    "$ROOT/index.html" \
    "$PACKAGE_ROOT/"

success "Copied index.html."

# Optional game directories.
for dir in "${OPTIONAL_DIRS[@]}"; do
    if [[ -d "$ROOT/$dir" ]]; then
        cp -rf \
            "$ROOT/$dir" \
            "$PACKAGE_ROOT/"

        success "Copied $dir/."
    fi
done

# Optional runtime files.
for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        cp -f \
            "$ROOT/$file" \
            "$PACKAGE_ROOT/"

        success "Copied $file."
    fi
done


# Copy Linux distribution files
info "Copying Linux launcher files..."

LINUX_FILES=(
    "codboz-td"
    "install.sh"
    "uninstall.sh"
    "codboz-td.desktop"
    "icon.svg"
    "package.sh"
)

for file in "${LINUX_FILES[@]}"; do
    cp -f \
        "$ROOT/linux/$file" \
        "$PACKAGE_ROOT/linux/"

    debug "Copied linux/$file"
done

success "Linux launcher files copied."


# Generate README
info "Generating README..."

cat > "$PACKAGE_ROOT/README.txt" <<'EOF'
COD TOWER DEFENSE — LINUX
=========================

Requirements:
  - Python 3
  - A web browser (Firefox, Chromium, or Chrome)

QUICK START
-----------

1) Enter the package directory:

   cd codboz-td

2) Install the game:

   ./linux/install.sh

3) Launch the game:

   codboz-td

The installer places the game under ~/.local/share and creates
a launcher and application-menu entry.

RUN WITHOUT INSTALLING
----------------------

You can also run the game directly:

   cd codboz-td
   ./linux/codboz-td

UNINSTALL
---------

From the original package directory:

   ./linux/uninstall.sh

Or, if the installer is still available:

   ./linux/install.sh --uninstall

CONTROLS
--------

  1-9                  Select build card
  Enter / Space       Start round
  Left click          Place / select tower
  Esc                 Pause / cancel / close
  Right click         Cancel build
  G                   Cycle player gun
  WASD / arrows       Dead Ops movement
  Hold left click     Shoot
EOF

success "README generated."


# Set executable permissions
info "Setting executable permissions..."

chmod +x \
    "$PACKAGE_ROOT/linux/codboz-td" \
    "$PACKAGE_ROOT/linux/install.sh" \
    "$PACKAGE_ROOT/linux/uninstall.sh" \
    "$PACKAGE_ROOT/linux/package.sh"

success "Executable permissions set."


# Validate staged package
info "Validating package contents..."

STAGED_REQUIRED=(
    "$PACKAGE_ROOT/index.html"
    "$PACKAGE_ROOT/README.txt"
    "$PACKAGE_ROOT/linux/codboz-td"
    "$PACKAGE_ROOT/linux/install.sh"
    "$PACKAGE_ROOT/linux/uninstall.sh"
    "$PACKAGE_ROOT/linux/codboz-td.desktop"
    "$PACKAGE_ROOT/linux/icon.svg"
    "$PACKAGE_ROOT/linux/package.sh"
)

for file in "${STAGED_REQUIRED[@]}"; do
    [[ -f "$file" ]] || \
        die "Staged package is missing: ${file#"$STAGE"/}"
done

success "Package contents validated."


# Create ZIP archive
info "Creating Linux distribution archive..."

python3 - "$OUT" "$STAGE" <<'PYEOF'
import os
import sys
import zipfile

out = sys.argv[1]
stage = sys.argv[2]
src = os.path.join(stage, "codboz-td")

files = []

for root, dirs, filenames in os.walk(src):
    dirs.sort()
    filenames.sort()

    for filename in filenames:
        full = os.path.join(root, filename)
        rel = os.path.relpath(full, stage)
        files.append((full, rel))

with zipfile.ZipFile(
    out,
    "w",
    compression=zipfile.ZIP_DEFLATED,
    compresslevel=9,
) as archive:
    for full, rel in files:
        archive.write(full, rel)

print(f"Archived {len(files)} files.")
PYEOF

[[ -f "$OUT" ]] || die "ZIP archive was not created."

success "Linux distribution archive created."


# Verify ZIP archive
info "Verifying ZIP archive..."

python3 - "$OUT" <<'PYEOF'
import sys
import zipfile

archive_path = sys.argv[1]

with zipfile.ZipFile(archive_path, "r") as archive:
    bad = archive.testzip()

    if bad is not None:
        raise SystemExit(f"Corrupt ZIP entry: {bad}")

    names = archive.namelist()

required = {
    "codboz-td/index.html",
    "codboz-td/README.txt",
    "codboz-td/linux/codboz-td",
    "codboz-td/linux/install.sh",
    "codboz-td/linux/uninstall.sh",
    "codboz-td/linux/codboz-td.desktop",
    "codboz-td/linux/icon.svg",
    "codboz-td/linux/package.sh",
}

missing = sorted(required - set(names))

if missing:
    print("Missing required ZIP entries:", file=sys.stderr)

    for item in missing:
        print(f"  {item}", file=sys.stderr)

    raise SystemExit(1)

print(f"Verified {len(names)} archive entries.")
PYEOF

success "ZIP archive verified successfully."


# Package summary
SIZE="$(du -h "$OUT" | cut -f1)"

echo
echo "============================================================"
echo "  COD Tower Defense Linux package built successfully!"
echo "============================================================"
echo
echo "  Package:"
echo "    $OUT"
echo
echo "  Size:"
echo "    $SIZE"
echo
echo "  Contents:"
echo "    codboz-td/"
echo "    ├── index.html"
echo "    ├── README.txt"
echo "    └── linux/"
echo "        ├── codboz-td"
echo "        ├── install.sh"
echo "        ├── uninstall.sh"
echo "        ├── codboz-td.desktop"
echo "        ├── icon.svg"
echo "        └── package.sh"
echo
echo "Copy this archive to a Linux machine and extract it."
echo "Then run:"
echo
echo "    cd codboz-td"
echo "    ./linux/install.sh"
echo
echo "============================================================"

STAGE=""

exit 0
