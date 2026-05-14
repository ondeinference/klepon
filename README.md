# Klepon: Taste of Indonesia

[![Join the Klepon TestFlight](https://img.shields.io/badge/TestFlight-Join%20beta-0A84FF?logo=apple&logoColor=white)](https://testflight.apple.com/join/CRRpT6a5)

Klepon is an iPhone-first SwiftUI app for exploring Indonesian dishes, ingredients, and food traditions. The app is built to feel warm, simple, and curated rather than like a generic chatbot or a giant food database.

## Why this project exists

Indonesian food deserves better than scattered search results and shallow summaries.

Klepon is a small, focused app project built to help people:

- discover Indonesian dishes with context
- understand ingredients and food traditions
- browse locally bundled content with a calmer reading experience
- ask follow-up questions privately on-device

## Project status

This repo is under active development, but the V1 direction is already in place:

- curated Indonesian food content bundled locally
- private on-device follow-up answers powered by [Onde Inference](https://ondeinference.com).
- iPhone-first SwiftUI UI and interaction model
- watchOS companion support for quick browse-first dish notes
- local search, saved items, recent searches, and recently viewed continuity

## Repository layout

- `Klepon/` — the iOS app source
- `Klepon.xcodeproj/` — the Xcode project
- `Scripts/validate_content.py` — validates bundled content integrity
- `SECURITY.md` — security handling and disclosure guidance
- `AppStore/` — App Store metadata, screenshot plan, and release checklists

## Tech stack

- SwiftUI
- local JSON content
- small Python utility for content validation

## Getting started

### Requirements

- macOS
- Xcode 26+
- Python 3 if you want to run the content validation script
- an Apple Developer signing setup if you want to run on a physical iPhone

### Open the project

Open:

- `Klepon.xcodeproj`

### Build on simulator

```/dev/null/sh#L1-1
xcodebuild -project Klepon.xcodeproj -scheme Klepon -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### Build the watchOS target

```/dev/null/sh#L1-1
xcodebuild -project Klepon.xcodeproj -scheme 'Klepon Watch' -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### Validate bundled content

```/dev/null/sh#L1-1
python3 Scripts/validate_content.py
```

## Open-source signing notes

This repository is published as source code, so you should expect to adapt signing-related settings for your own Apple Developer account.

### Bundle identifier

The project currently uses:

- `ai.splitfire.klepon`

If you fork this project for your own team, change that bundle identifier to one you control.

### Entitlements and App Group

The project includes an App Group entitlement and an increased memory entitlement so the app can manage on-device model files more reliably on iPhone.

If you run your own fork under your own Apple Developer account, you will usually want to replace the App Group identifier with one you control.

## Security and secrets

I checked the repository for common secret-leak patterns before updating this README.

That included scans for things like:

- API keys
- private keys
- password-like values
- provisioning material
- hardcoded team identifiers in the active project

No real secrets were found in the tracked project files.

### What should never be committed

- API keys
- private keys or certificates
- provisioning profiles
- local-only xcconfig files with secrets
- `.env` files with credentials

### Practical security rules for this repo

1. Keep local credentials local.
2. Never hardcode tokens or keys in Swift, JSON, or Xcode project settings.
3. Treat bundle IDs and App Groups as identifiers, not secrets.
4. Replace shared signing identifiers with your own if you are running a fork.
5. Re-check diffs before pushing anything that touches auth, signing, or deployment.

The `.gitignore` already excludes the main categories of files that should stay off Git:

- local env files
- local xcconfig overrides
- signing keys and certificates
- provisioning profiles
- editor and user-state files
- Python cache files

For more detail, see `SECURITY.md`.

## Contributing

Contributions are welcome, especially around:

- content quality and cultural accuracy
- SwiftUI product polish
- accessibility
- app performance and memory behavior

Before opening a PR:

1. build the app
2. run `python3 Scripts/validate_content.py` if you changed bundled content
3. make sure you did not add secrets, signing material, or local machine artifacts

## Responsible disclosure

If you find a security issue, please avoid posting exploit details in a public issue before maintainers have had a chance to triage it.

## License

Klepon is dual-licensed under **MIT** and **Apache 2.0**. You can use either one.

- [MIT License](LICENSE-MIT)
- [Apache License 2.0](LICENSE-APACHE)

---

## Copyright

© 2026 [Onde Inference](https://ondeinference.com) (Splitfire AB).
