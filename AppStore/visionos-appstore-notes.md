# visionOS App Store notes

## Bundle identifier

The visionOS target uses the same bundle identifier as the iPhone app:

- `ai.splitfire.klepon`

That keeps the main Apple-platform app identity aligned across iPhone, Mac, and visionOS. The watch companion still uses its own watch bundle identifier, which Apple requires for the companion app target.

## App shape

The current visionOS target is intentionally simple for v1.

- It is a windowed SwiftUI app
- It does not use immersive spaces
- It reuses the shared browse-first Klepon experience

This is deliberate. The goal is a clean, stable App Store MVP that showcases Onde on Apple Vision Pro without forcing a spatial-first redesign yet.

## Required configuration

The visionOS target uses:

- `KleponVision/Info.plist`
- `KleponVision/KleponVision.entitlements`

Important settings:

- `ITSAppUsesNonExemptEncryption = false`
- `com.apple.security.application-groups = group.com.ondeinference.apps`

The App Group keeps local model storage aligned with the other Apple targets.

## Build and archive

Generate the project:

```/dev/null/sh#L1-1
xcodegen generate
```

Build the visionOS target locally:

```/dev/null/sh#L1-1
xcodebuild build -project Klepon.xcodeproj -scheme 'Klepon Vision' -destination 'generic/platform=visionOS Simulator'
```

Archive the visionOS target:

```/dev/null/sh#L1-1
xcodebuild archive -project Klepon.xcodeproj -scheme 'Klepon Vision' -destination 'generic/platform=visionOS' -archivePath build/KleponVision.xcarchive
```

## Submission checklist

Before upload, confirm:

- the signing profile is for `ai.splitfire.klepon`
- the App Group capability exists for the shipping team
- the app opens as a clean windowed experience on Apple Vision Pro
- visionOS screenshots and metadata are ready in `AppStore/screenshots/visionos/` and `AppStore/metadata-visionos/en-US/`
