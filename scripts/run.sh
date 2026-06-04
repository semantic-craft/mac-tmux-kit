#!/bin/bash
# Build, re-sign with the stable Apple Development identity, and (re)launch.
#
# Why re-sign: xcodebuild signs the app ad-hoc, whose code hash changes every
# build and silently invalidates the macOS Accessibility (TCC) grant. Re-signing
# the finished bundle with a real Development certificate gives a stable identity,
# so you only grant Accessibility once. Must run AFTER xcodebuild (its built-in
# CodeSign step would otherwise overwrite an in-build re-sign).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> xcodegen generate"
xcodegen generate >/dev/null

echo "==> xcodebuild"
xcodebuild -project MacTmuxKit.xcodeproj -scheme MacTmuxKit -configuration Debug build \
  >/tmp/mactmuxkit-build.log 2>&1 || { tail -30 /tmp/mactmuxkit-build.log; exit 1; }

APP="$(ls -d ~/Library/Developer/Xcode/DerivedData/MacTmuxKit-*/Build/Products/Debug/MacTmuxKit.app | head -1)"
echo "==> built: $APP"

ID="$(security find-identity -v -p codesigning | awk '/Apple Development/{print $2; exit}')"
if [ -n "${ID:-}" ]; then
  echo "==> re-signing with $ID"
  codesign --force --deep --sign "$ID" "$APP"
else
  echo "==> WARNING: no Apple Development identity; leaving ad-hoc (TCC grant will not persist)"
fi

echo "==> relaunching"
pkill -x MacTmuxKit 2>/dev/null || true
sleep 0.5
open "$APP"
echo "==> done. Signature:"
codesign -dvv "$APP" 2>&1 | grep -E "Authority=Apple Development|Signature=adhoc" | head -1
