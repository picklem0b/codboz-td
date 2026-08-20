#!/usr/bin/env bash
# ============================================================
# COD Tower Defense — Linux installer
#
# Installs the game to the user's local data directory,
# installs the launcher to ~/.local/bin, and adds a desktop
# entry + icon so the game appears in the application menu.
#
# Usage:
#   ./install.sh
#   ./install.sh --help
#   ./install.sh --uninstall
#   ./install.sh --verbose
# ============================================================

set -euo pipefail


# Configuration
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Respect XDG_DATA_HOME when provided, otherwise use the
# standard ~/.local/share location.
XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"

DEST="$XDG_DATA_HOME/codboz-td"
BIN="$HOME/.local/bin"
APPS="$XDG_DATA_HOME/applications"
ICONS="$XDG_DATA_HOME/icons/hicolor/scalable/apps"

LAUNCHER="$BIN/codboz-td"
DESKTOP="$APPS/codboz-td.desktop"
ICON="$ICONS/codboz-td.svg"

STAGING=""
BACKUP=""

VERBOSE=0


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

run() {
    debug "$*"

    if [[ "$VERBOSE" -eq 1 ]]; then
        "$@"
    else
        "$@" >/dev/null
    fi
}

# Usage
usage() {
    cat <<EOF
COD Tower Defense — Linux installer

Usage:
  $(basename "$0") [OPTIONS]

Options:
  -h, --help        Show this help message
  -v, --verbose     Show additional installation details
      --uninstall   Run the game's uninstall script

The normal installation:
  • Installs game files to:
      $DEST

  • Installs launcher to:
      $LAUNCHER

  • Installs desktop entry to:
      $DESKTOP

  • Installs icon to:
      $ICON
EOF
}


# Argument parsing
UNINSTALL=0

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

        --uninstall)
            UNINSTALL=1
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


# Uninstall
if [[ "$UNINSTALL" -eq 1 ]]; then
    UNINSTALL_SCRIPT="$ROOT/linux/uninstall.sh"

    [[ -f "$UNINSTALL_SCRIPT" ]] || \
        die "Uninstall script not found: $UNINSTALL_SCRIPT"

    [[ -x "$UNINSTALL_SCRIPT" ]] || \
        die "Uninstall script is not executable: $UNINSTALL_SCRIPT"

    exec "$UNINSTALL_SCRIPT"
fi


# Cleanup / rollback handling
cleanup() {
    local status=$?

    if [[ -n "${STAGING:-}" && -d "$STAGING" ]]; then
        debug "Removing staging directory: $STAGING"
        rm -rf "$STAGING"
    fi

    if [[ "$status" -ne 0 ]]; then
        error "Installation failed."

        # If we created a backup and installation failed, restore it.
        if [[ -n "${BACKUP:-}" && -d "$BACKUP" ]]; then
            warning "Restoring previous installation..."

            rm -rf "$DEST"

            if mv "$BACKUP" "$DEST"; then
                success "Previous installation restored."
            else
                error "Could not restore the previous installation."
            fi
        fi
    fi

    exit "$status"
}

trap cleanup EXIT INT TERM


# Validate environment
[[ -n "${HOME:-}" ]] || die "HOME is not set."
[[ -d "$ROOT" ]] || die "Project root does not exist: $ROOT"

info "Checking installer environment..."

command -v mkdir >/dev/null 2>&1 || die "'mkdir' is required."
command -v cp >/dev/null 2>&1 || die "'cp' is required."
command -v install >/dev/null 2>&1 || die "'install' is required."
command -v sed >/dev/null 2>&1 || die "'sed' is required."
command -v mv >/dev/null 2>&1 || die "'mv' is required."
command -v rm >/dev/null 2>&1 || die "'rm' is required."

success "Required system tools are available."


# Validate required source files
info "Checking game files..."

[[ -f "$ROOT/index.html" ]] || \
    die "Required game file is missing: $ROOT/index.html"

[[ -f "$ROOT/linux/codboz-td" ]] || \
    die "Required launcher is missing: $ROOT/linux/codboz-td"

[[ -f "$ROOT/linux/codboz-td.desktop" ]] || \
    die "Required desktop entry is missing: $ROOT/linux/codboz-td.desktop"

[[ -f "$ROOT/linux/icon.svg" ]] || \
    die "Required icon is missing: $ROOT/linux/icon.svg"

success "Required game files are present."


# Optional runtime files
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
        debug "Optional directory found: $dir"
    else
        debug "Optional directory missing: $dir"
    fi
done

for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        debug "Optional file found: $file"
    else
        debug "Optional file missing: $file"
    fi
done

success "Game file validation complete."


# Check optional tools
if command -v rsync >/dev/null 2>&1; then
    HAS_RSYNC=1
    debug "rsync detected; directory copies will use rsync."
else
    HAS_RSYNC=0
    debug "rsync not found; falling back to cp."
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    HAS_DESKTOP_DATABASE=1
    debug "update-desktop-database detected."
else
    HAS_DESKTOP_DATABASE=0
    debug "update-desktop-database not found; desktop refresh will be skipped."
fi


# Display installation plan
echo
echo "COD Tower Defense installer"
echo "────────────────────────────────────────────────────────"
echo "  game  → $DEST"
echo "  bin   → $LAUNCHER"
echo "  menu  → $DESKTOP"
echo "  icon  → $ICON"
echo "────────────────────────────────────────────────────────"
echo


# Create required directories
info "Preparing installation directories..."

mkdir -p \
    "$XDG_DATA_HOME" \
    "$BIN" \
    "$APPS" \
    "$ICONS"

success "Installation directories ready."


# Create staging directory
info "Creating temporary installation..."

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/codboz-td.XXXXXX")"
STAGED_GAME="$STAGING/game"
STAGED_BIN="$STAGING/bin"
STAGED_APPS="$STAGING/applications"
STAGED_ICONS="$STAGING/icons"

mkdir -p \
    "$STAGED_GAME" \
    "$STAGED_BIN" \
    "$STAGED_APPS" \
    "$STAGED_ICONS"

success "Temporary installation created."


# Copy game files
info "Installing game files..."

# Required game file.
cp -f "$ROOT/index.html" "$STAGED_GAME/"

# Optional game directories.
for dir in "${OPTIONAL_DIRS[@]}"; do
    if [[ -d "$ROOT/$dir" ]]; then
        if [[ "$HAS_RSYNC" -eq 1 ]]; then
            rsync -a --delete "$ROOT/$dir/" "$STAGED_GAME/$dir/"
        else
            cp -rf "$ROOT/$dir" "$STAGED_GAME/"
        fi
    fi
done

# Optional runtime files.
for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        cp -f "$ROOT/$file" "$STAGED_GAME/"
    fi
done

success "Game files installed."


# Install launcher
info "Installing launcher..."

install -m755 \
    "$ROOT/linux/codboz-td" \
    "$STAGED_BIN/codboz-td"

success "Launcher installed."


# Generate desktop entry
info "Installing desktop entry..."

# Replace only the launcher command while preserving every other
# line from the project's existing desktop entry.
sed "s|^Exec=codboz-td$|Exec=$LAUNCHER|" \
    "$ROOT/linux/codboz-td.desktop" \
    > "$STAGED_APPS/codboz-td.desktop"

chmod 644 "$STAGED_APPS/codboz-td.desktop"

success "Desktop entry installed."


# Install icon
info "Installing application icon..."

cp -f \
    "$ROOT/linux/icon.svg" \
    "$STAGED_ICONS/codboz-td.svg"

success "Application icon installed."


# Backup existing installation
if [[ -e "$DEST" ]]; then
    info "Backing up existing installation..."

    BACKUP="$(mktemp -d "${TMPDIR:-/tmp}/codboz-td-backup.XXXXXX")"

    # Move the existing installation into the backup location.
    mv "$DEST" "$BACKUP/game"

    success "Previous installation backed up."
fi


# Activate staged installation
info "Activating installation..."

mv "$STAGED_GAME" "$DEST"

# The staged launcher, desktop entry and icon are individual files,
# so install them only after the game directory has been activated.
install -m755 \
    "$STAGED_BIN/codboz-td" \
    "$LAUNCHER"

install -m644 \
    "$STAGED_APPS/codboz-td.desktop" \
    "$DESKTOP"

install -m644 \
    "$STAGED_ICONS/codboz-td.svg" \
    "$ICON"

success "Installation activated."


# Remove backup after successful installation
if [[ -n "${BACKUP:-}" && -d "$BACKUP" ]]; then
    info "Removing previous installation backup..."

    rm -rf "$BACKUP"
    BACKUP=""

    success "Previous installation removed."
fi


# Refresh desktop database
if [[ "$HAS_DESKTOP_DATABASE" -eq 1 ]]; then
    info "Refreshing application menu..."

    if update-desktop-database "$APPS" >/dev/null 2>&1; then
        success "Application menu refreshed."
    else
        warning "Could not refresh the application menu."
        warning "Your desktop environment may refresh it automatically."
    fi
else
    warning "update-desktop-database is not installed."
    warning "The application menu may refresh automatically."
fi


# PATH check
echo

if [[ ":${PATH}:" == *":$BIN:"* ]]; then
    success "$BIN is already in PATH."
else
    warning "$BIN is not currently in PATH."

    echo
    echo "Add it to your PATH if you want to launch with:"
    echo "    codboz-td"
    echo
    echo "For Bash:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    echo "For Zsh:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

 
# Final status
echo
echo "============================================================"
echo "  COD Tower Defense installed successfully!"
echo "============================================================"
echo
echo "Launch it with:"
echo "    $LAUNCHER"
echo
echo "Or, if $BIN is in your PATH:"
echo "    codboz-td"
echo
echo "You can also launch it from your application menu:"
echo "    COD Tower Defense"
echo
echo "Uninstall with:"
echo "    $ROOT/linux/uninstall.sh"
echo
echo "Or:"
echo "    $0 --uninstall"
echo

 
# Final cleanup
STAGING=""

exit 0
