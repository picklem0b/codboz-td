#!/usr/bin/env bash
# ============================================================
# COD Tower Defense — Linux uninstaller
#
# Removes:
#   • Installed game files
#   • Launcher
#   • Desktop entry
#   • Application icon
#
# Usage:
#   ./uninstall.sh
#   ./uninstall.sh --help
#   ./uninstall.sh --verbose
#   ./uninstall.sh --yes
# ============================================================

set -euo pipefail

# Configuration
XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"

DEST="$XDG_DATA_HOME/codboz-td"
BIN="$HOME/.local/bin"
APPS="$XDG_DATA_HOME/applications"
ICONS="$XDG_DATA_HOME/icons/hicolor/scalable/apps"

LAUNCHER="$BIN/codboz-td"
DESKTOP="$APPS/codboz-td.desktop"
ICON="$ICONS/codboz-td.svg"

VERBOSE=0
ASSUME_YES=0


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
COD Tower Defense — Linux uninstaller

Usage:
  $(basename "$0") [OPTIONS]

Options:
  -h, --help      Show this help message
  -v, --verbose   Show additional details
  -y, --yes       Skip the confirmation prompt

The following will be removed:

  Game:
    $DEST

  Launcher:
    $LAUNCHER

  Desktop entry:
    $DESKTOP

  Icon:
    $ICON
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

        -y|--yes)
            ASSUME_YES=1
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


# Validate environment
[[ -n "${HOME:-}" ]] || die "HOME is not set."

command -v rm >/dev/null 2>&1 || die "'rm' is required."
command -v mkdir >/dev/null 2>&1 || die "'mkdir' is required."


# Display uninstall plan
echo
echo "COD Tower Defense uninstaller"
echo "────────────────────────────────────────────────────────"
echo "  game  -> $DEST"
echo "  bin   ->$LAUNCHER"
echo "  menu  -> $DESKTOP"
echo "  icon  -> $ICON"
echo "────────────────────────────────────────────────────────"
echo


# Check whether anything is installed
FOUND=0

[[ -e "$DEST" ]] && FOUND=1
[[ -e "$LAUNCHER" ]] && FOUND=1
[[ -e "$DESKTOP" ]] && FOUND=1
[[ -e "$ICON" ]] && FOUND=1

if [[ "$FOUND" -eq 0 ]]; then
    warning "COD Tower Defense does not appear to be installed."
    exit 0
fi


# Confirmation
if [[ "$ASSUME_YES" -eq 0 ]]; then
    read -r -p "Remove COD Tower Defense? [y/N] " ANSWER

    case "$ANSWER" in
        y|Y|yes|YES|Yes)
            ;;
        *)
            echo "Uninstall cancelled."
            exit 0
            ;;
    esac

    echo
fi


# Remove game files
if [[ -e "$DEST" ]]; then
    info "Removing game files..."

    rm -rf "$DEST"

    success "Game files removed."
else
    debug "Game installation not found."
fi


# Remove launcher
if [[ -e "$LAUNCHER" ]]; then
    info "Removing launcher..."

    rm -f "$LAUNCHER"

    success "Launcher removed."
else
    debug "Launcher not found."
fi


# Remove desktop entry
if [[ -e "$DESKTOP" ]]; then
    info "Removing desktop entry..."

    rm -f "$DESKTOP"

    success "Desktop entry removed."
else
    debug "Desktop entry not found."
fi


# Remove icon
if [[ -e "$ICON" ]]; then
    info "Removing application icon..."

    rm -f "$ICON"

    success "Application icon removed."
else
    debug "Application icon not found."
fi


# Clean empty icon directory
if [[ -d "$ICONS" ]]; then
    if [[ -z "$(find "$ICONS" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        debug "Removing empty icon directory."
        rmdir "$ICONS" 2>/dev/null || true
    fi
fi


# Refresh desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    info "Refreshing application menu..."

    if update-desktop-database "$APPS" >/dev/null 2>&1; then
        success "Application menu refreshed."
    else
        warning "Could not refresh the application menu."
        warning "Your desktop environment may refresh automatically."
    fi
else
    debug "update-desktop-database is not installed."
fi


# Final status
echo
echo "============================================================"
echo "  COD Tower Defense uninstalled successfully!"
echo "============================================================"
echo
echo "Removed:"
echo "  • Game files"
echo "  • Launcher"
echo "  • Desktop entry"
echo "  • Application icon"
echo
echo "Your personal project/source files were not touched."
echo
