<h1 align="center">Klepon</h1>

<p align="center">
  <strong>Taste of Indonesia.</strong>
</p>

<p align="center">
  <a href="https://apps.apple.com/us/app/klepon-taste-of-indonesia/id6769424800"><img src="https://img.shields.io/badge/App%20Store-Download-235843?style=flat-square&labelColor=17211D" alt="App Store"></a>
  <a href="https://testflight.apple.com/join/CRRpT6a5"><img src="https://img.shields.io/badge/TestFlight-Join%20beta-235843?style=flat-square&labelColor=17211D" alt="TestFlight"></a>
</p>

Klepon is a small SwiftUI guide to Indonesian dishes, ingredients, and food traditions.

## What it does

- curated local content
- private on-device follow-up answers with [Onde Inference](https://ondeinference.com)
- search, saved items, and recently viewed
- watchOS companion support

## Repo

- `Klepon/` app source
- `Klepon.xcodeproj/` Xcode project
- `Scripts/validate_content.py` content validation
- `AppStore/` store assets and release notes

## Build

Open `Klepon.xcodeproj` in Xcode.

iOS simulator:
```/dev/null/sh#L1-1
xcodebuild -project Klepon.xcodeproj -scheme Klepon -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

watchOS simulator:
```/dev/null/sh#L1-1
xcodebuild -project Klepon.xcodeproj -scheme 'Klepon Watch' -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Validate bundled content:
```/dev/null/sh#L1-1
python3 Scripts/validate_content.py
```

## Signing

If you run your own fork, change the bundle identifier and App Group to values you control.

## License

Dual-licensed under [MIT](LICENSE-MIT) or [Apache 2.0](LICENSE-APACHE).
