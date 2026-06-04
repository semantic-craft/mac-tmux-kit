#!/bin/bash
# Build a standalone Release .app, sign it with the stable Apple Development
# identity, and install it (default: /Applications, falling back to ~/Applications).
#
# Because it's signed with the same certificate + bundle id as the dev build,
# the macOS Accessibility (TCC) grant carries over -- no need to re-authorize.
# This is for LOCAL use on this Mac; distributing to other Macs would require a
# Developer ID certificate + notarization (a paid Apple Developer account).
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${1:-/Applications}"

echo "==> xcodegen generate"
xcodegen generate >/dev/null

echo "==> xcodebuild (Release, clean)"
rm -rf build
xcodebuild -project MacTmuxKit.xcodeproj -scheme MacTmuxKit -configuration Release \
  -derivedDataPath build build CODE_SIGNING_ALLOWED=NO \
  >/tmp/mactmuxkit-release.log 2>&1 || { tail -40 /tmp/mactmuxkit-release.log; exit 1; }

APP="build/Build/Products/Release/MacTmuxKit.app"
[ -d "$APP" ] || { echo "Release .app not found at $APP"; exit 1; }

ID="$(security find-identity -v -p codesigning | awk '/Apple Development/{print $2; exit}')"
if [ -n "${ID:-}" ]; then
  echo "==> signing with $ID"
  codesign --force --deep --sign "$ID" "$APP"
else
  echo "==> WARNING: no Apple Development identity; app stays ad-hoc (TCC grant will not persist)"
fi

install_to() {
  local dir="$1"
  mkdir -p "$dir" 2>/dev/null || return 1
  rm -rf "$dir/MacTmuxKit.app" 2>/dev/null || true
  cp -R "$APP" "$dir/" 2>/dev/null || return 1
  echo "$dir/MacTmuxKit.app"
}

TARGET="$(install_to "$DEST" || true)"
if [ -z "${TARGET:-}" ]; then
  echo "==> $DEST not writable; falling back to ~/Applications"
  TARGET="$(install_to "$HOME/Applications")"
fi

echo "==> installed: $TARGET"
codesign -dvv "$TARGET" 2>&1 | grep -E "Authority=Apple Development|Signature=adhoc" | head -1

# Relaunch the installed copy.
pkill -x MacTmuxKit 2>/dev/null || true
sleep 0.5
open "$TARGET"
echo "==> launched $TARGET"
