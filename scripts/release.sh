#!/bin/bash
# Build a distributable, Developer-ID-signed, notarized DMG of Tmux Kit.
#
# Prerequisites (one-time, requires a paid Apple Developer Program membership):
#   1. A "Developer ID Application" certificate in your keychain
#      (Xcode > Settings > Accounts > Manage Certificates > + > Developer ID Application).
#   2. A stored notarization credential profile:
#        xcrun notarytool store-credentials MacTmuxKitNotary \
#          --apple-id "you@example.com" --team-id "TEAMID" \
#          --password "app-specific-password"      # appleid.apple.com > App-Specific Passwords
#
# Then: ./scripts/release.sh
# Output: dist/MacTmuxKit-<version>.dmg  (signed, notarized, stapled)
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${NOTARY_PROFILE:-MacTmuxKitNotary}"

# 1. Developer ID Application certificate.
DEVID="$(security find-identity -v -p codesigning | sed -n 's/.*\"\(Developer ID Application[^\"]*\)\".*/\1/p' | head -1)"
if [ -z "$DEVID" ]; then
  cat <<'MSG'
ERROR: no "Developer ID Application" certificate found.

This needs a paid Apple Developer Program membership ($99/yr). Then in Xcode:
  Settings > Accounts > (your team) > Manage Certificates > + > Developer ID Application
Re-run this script once the certificate is in your keychain.

(Until then, scripts/build-app.sh produces a locally-signed build that runs on
THIS Mac; other Macs would need right-click > Open the first time.)
MSG
  exit 1
fi
echo "==> Developer ID: $DEVID"

echo "==> xcodebuild (Release, clean)"
rm -rf build dist
xcodebuild -project MacTmuxKit.xcodeproj -scheme MacTmuxKit -configuration Release \
  -derivedDataPath build build CODE_SIGNING_ALLOWED=NO \
  >/tmp/mactmuxkit-release.log 2>&1 || { tail -40 /tmp/mactmuxkit-release.log; exit 1; }

APP="build/Build/Products/Release/MacTmuxKit.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
echo "==> built $APP (v$VERSION)"

# 2. Sign nested code first, then the app, with Hardened Runtime + secure timestamp.
sign() { codesign --force --options runtime --timestamp --sign "$DEVID" "$1"; }
echo "==> signing (hardened runtime + timestamp)"
find "$APP/Contents" \( -name "*.framework" -o -name "*.dylib" \) -print0 \
  | while IFS= read -r -d '' f; do sign "$f"; done
sign "$APP"
codesign --verify --strict --verbose=2 "$APP"

# 3. Notarize a zip of the app, then staple the ticket into the .app.
mkdir -p dist
ZIP="dist/MacTmuxKit-$VERSION.zip"
echo "==> zipping for notarization"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> notarizing (profile: $PROFILE) — this can take a few minutes"
if ! xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait; then
  cat <<MSG
ERROR: notarization failed or the credential profile "$PROFILE" is missing.

Create it once:
  xcrun notarytool store-credentials $PROFILE \\
    --apple-id "you@example.com" --team-id "TEAMID" \\
    --password "app-specific-password"
Then re-run. (Set NOTARY_PROFILE to use a different profile name.)
MSG
  exit 1
fi

echo "==> stapling"
xcrun stapler staple "$APP"
rm -f "$ZIP"

# 4. Build a drag-to-install DMG from the stapled app.
echo "==> building DMG"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
DMG="dist/MacTmuxKit-$VERSION.dmg"
hdiutil create -volname "Tmux Kit" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "==> done: $DMG"
codesign -dvv "$APP" 2>&1 | grep -E "Authority=Developer ID" | head -1
xcrun stapler validate "$APP" || true
