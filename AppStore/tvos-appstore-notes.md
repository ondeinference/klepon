# tvOS App Store notes

## Bundle identifier

The tvOS target uses the same bundle identifier as the iPhone app:

- `ai.splitfire.klepon`

That keeps the main Apple-platform app identity aligned across iPhone, Apple TV, Mac, and visionOS. The watch companion still uses its own watch bundle identifier, which Apple requires for the companion app target.

## App shape

The current tvOS target is intentionally simple for v1.

- It is a focus-friendly SwiftUI app
- It uses tabs and navigation stacks
- It keeps the private guide inside the existing browse-first experience

This is deliberate. The goal is a clean, stable App Store MVP for Apple TV without overbuilding the first release.

## Required configuration

The tvOS target uses:

- `KleponTV/Info.plist`
- `KleponTV/KleponTV.entitlements`

Important settings:

- `ITSAppUsesNonExemptEncryption = false`
- `com.apple.security.application-groups = group.com.ondeinference.apps`

The App Group keeps local model storage aligned with the other Apple targets.

## Build and archive

Generate the project:

```/dev/null/sh#L1-1
xcodegen generate
```

Build the tvOS target locally:

```/dev/null/sh#L1-1
xcodebuild build -project Klepon.xcodeproj -scheme 'Klepon TV' -destination 'generic/platform=tvOS Simulator'
```

Archive the tvOS target:

```/dev/null/sh#L1-1
xcodebuild archive -project Klepon.xcodeproj -scheme 'Klepon TV' -destination 'generic/platform=tvOS' -archivePath build/KleponTV.xcarchive
```

## Submission checklist

Before upload, confirm:

- the signing profile is for `ai.splitfire.klepon`
- the App Group capability exists for the shipping team
- the app feels clean and navigable with the Siri Remote focus model
- tvOS screenshots and metadata are ready in `AppStore/screenshots/tvos/` and `AppStore/metadata-tvos/en-US/`
