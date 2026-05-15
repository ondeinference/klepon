# macOS App Store notes

## Bundle identifier

The macOS app now uses the same bundle identifier as the iPhone app:

- `ai.splitfire.klepon`

This keeps the main Apple-platform app identity aligned across iPhone and Mac. The watch companion still uses its own watch bundle identifier, which Apple requires for the companion app target.

## Required entitlements

The macOS target uses:

- `KleponMac/KleponMac.entitlements`

Required keys for the shipping App Store build:

- `com.apple.security.app-sandbox = true`
- `com.apple.security.network.client = true`
- `com.apple.security.application-groups = group.com.ondeinference.apps`

The sandbox entitlement is mandatory for App Store validation. The network entitlement is needed because Onde can download the optional on-device guide. The app group keeps local model storage aligned with the other Apple targets.

## Xcode project notes

The macOS target must not package the iPhone target's support files inside the app bundle.

In `project.yml`, the macOS target excludes:

- `Klepon/Info.plist`
- `Klepon/Klepon.entitlements`

Without those exclusions, Xcode can copy the iPhone plist into `Klepon.app/Contents/Resources/Info.plist`, which leads to App Store validation failures about invalid bundle identifiers, bad `CFBundleExecutable`, and duplicate bundle paths.

## Build and archive

Generate the project:

```/dev/null/sh#L1-1
xcodegen generate
```

Build the macOS target locally:

```/dev/null/sh#L1-1
xcodebuild build -project Klepon.xcodeproj -scheme 'Klepon Mac' -destination 'platform=macOS'
```

Archive the macOS target:

```/dev/null/sh#L1-1
xcodebuild archive -project Klepon.xcodeproj -scheme 'Klepon Mac' -destination 'generic/platform=macOS' -archivePath build/KleponMac.xcarchive
```

## Submission checklist

Before upload, confirm:

- the signing profile is for `ai.splitfire.klepon`
- the archive contains `Klepon.app/Contents/Info.plist` and no extra `Contents/Resources/Info.plist`
- App Sandbox is enabled in the signed app
- the App Group capability exists for the shipping team
- macOS screenshots and macOS metadata are ready in `AppStore/screenshots/macos/` and `AppStore/metadata-macos/en-US/`
