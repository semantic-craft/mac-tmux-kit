# Releasing Tmux Kit

Tmux Kit is **not distributable through the Mac App Store** (see "Why not the App
Store" below). The supported channel is **Developer ID + notarization**, which
runs on any Mac with no Gatekeeper warning and keeps every feature.

## One-time setup (needs a paid Apple Developer Program membership, $99/yr)

1. Create a **Developer ID Application** certificate:
   Xcode > Settings > Accounts > *your team* > Manage Certificates > + >
   *Developer ID Application*.
2. Store a notarization credential profile:
   ```sh
   xcrun notarytool store-credentials MacTmuxKitNotary \
     --apple-id "you@example.com" --team-id "YOURTEAMID" \
     --password "app-specific-password"   # from appleid.apple.com > App-Specific Passwords
   ```

## Build a release

```sh
./scripts/release.sh
# → dist/MacTmuxKit-<version>.dmg  (signed, notarized, stapled)
```

Attach the DMG to a GitHub Release.

## Local / personal builds (no paid account)

```sh
./scripts/build-app.sh   # installs a locally-signed .app to /Applications
./scripts/run.sh         # dev build + re-sign + relaunch
```
These run on **your** Mac. On other Macs, the first launch needs right-click > Open.

## Why not the App Store

The Mac App Store requires the **App Sandbox**, which forbids exactly what this app
does: executing the external `tmux` binary, controlling other apps' windows via the
Accessibility API, and launching/raising the terminal. A sandboxed build would lose
its core features and be rejected. Terminal/window utilities in this category
(Rectangle, iTerm2, Raycast, Warp, …) distribute outside the App Store for the same
reason. Developer ID + notarization is the correct path.
