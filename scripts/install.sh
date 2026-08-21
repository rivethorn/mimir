#!/usr/bin/env bash
# Install script for Linux/macOS:
# - detects OS/arch, downloads the latest mimir release artifact from GitHub,
# - extracts to temporary dir,
# - copies the downloaded binary directly into ~/.mimir/bin,
# - ensures ~/.mimir/bin is on PATH for common shells,
# - cleans up.
set -euo pipefail

REPO="rivethorn/mimir"
TEMP_DIR="$(mktemp -d)"
ARCH=""
OS=""
OUTDIR="$HOME/.mimir/bin"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Detect OS
uname_s="$(uname -s)"
case "$uname_s" in
Linux*) OS=linux ;;
Darwin*) OS=macos ;;
*)
    echo "Unsupported OS: $uname_s"
    exit 1
    ;;
esac

# Detect arch
uname_m="$(uname -m)"
case "$uname_m" in
x86_64 | amd64) ARCH=x64 ;;
aarch64 | arm64) ARCH=arm64 ;;
*)
    echo "Unsupported arch: $uname_m"
    exit 1
    ;;
esac

echo "Detected: OS=${OS}, ARCH=${ARCH}"

# Build expected asset name patterns (matches CI release naming)
if [ "$OS" = "windows" ]; then
    # not used here
    ASSET_PAT="mimir-${OS}-${ARCH}.zip"
else
    ASSET_PAT="mimir-${OS}-${ARCH}.tar.gz"
fi

# Query GitHub API for latest release asset
API="https://api.github.com/repos/${REPO}/releases/latest"
echo "Querying GitHub releases for ${REPO}..."
ASSET_URL=$(curl -s "$API" |
    grep "browser_download_url" |
    grep -i "mimir" |
    grep -i "$OS" |
    grep -i "$ARCH" |
    head -n1 |
    cut -d '"' -f4 || true)

if [ -z "$ASSET_URL" ]; then
    echo "Could not find release asset matching ${ASSET_PAT}."
    echo "Available assets:"
    curl -s "$API" | grep "browser_download_url" || true
    exit 1
fi

echo "Downloading asset: $ASSET_URL"
cd "$TEMP_DIR"
curl -L -o artifact "$ASSET_URL"

# Extract
mkdir -p "$TEMP_DIR/extracted"
if [[ "$ASSET_URL" == *.zip ]]; then
    unzip -q artifact -d extracted
else
    tar -xzf artifact -C extracted
fi

# Find the downloaded mimir binary in extracted
MIMIR_BIN="$(find extracted -maxdepth 2 -type f -name 'mimir' -o -name 'mimir.exe' | head -n1)"
if [ -z "$MIMIR_BIN" ]; then
    echo "Downloaded archive does not contain 'mimir' binary"
    ls -la extracted
    exit 1
fi

chmod +x "$MIMIR_BIN"

# Place the downloaded binary directly at the destination (no bootstrap)
mkdir -p "$OUTDIR"
cp "$MIMIR_BIN" "$OUTDIR/mimir"
chmod +x "$OUTDIR/mimir"
echo "Installed mimir to $OUTDIR/mimir"

# Add ~/.mimir/bin to PATH in common shells (idempotent)
EXPORT_LINE='export PATH="$HOME/.mimir/bin:$PATH"'

add_to_file_if_missing() {
    local file="$1"
    local line="$2"
    mkdir -p "$(dirname "${file}")"
    touch "${file}"
    grep -qxF "${line}" "${file}" || printf "\n%s\n" "${line}" >>"${file}"
}

add_to_file_if_missing "${HOME}/.profile" "${EXPORT_LINE}"
add_to_file_if_missing "${HOME}/.bashrc" "${EXPORT_LINE}"
add_to_file_if_missing "${HOME}/.zshrc" "${EXPORT_LINE}"
add_to_file_if_missing "${HOME}/.zprofile" "${EXPORT_LINE}"

# fish
FISH_CONF_DIR="${HOME}/.config/fish/conf.d"
mkdir -p "${FISH_CONF_DIR}"
FISH_FILE="${FISH_CONF_DIR}/mimir.fish"
FISH_LINE='set -gx PATH $HOME/.mimir/bin $PATH'
if [ ! -f "${FISH_FILE}" ] || ! grep -qxF "${FISH_LINE}" "${FISH_FILE}"; then
    printf "%s\n" "${FISH_LINE}" >"${FISH_FILE}"
fi

echo "Install finished. Cleaned up temp files."
echo "Ensure you open a new shell or source your profile to pick up PATH changes."
