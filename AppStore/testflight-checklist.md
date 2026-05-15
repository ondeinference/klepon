# TestFlight checklist

## Product sanity

- [ ] Discover screen feels complete on first launch
- [ ] Search returns sensible results for core dishes
- [ ] Saved items persist across app relaunch
- [ ] Ask flow works without turning into a generic chat experience
- [ ] Watch app launches and browses correctly

## Technical checks

- [ ] iPhone target builds on simulator
- [ ] iPhone target runs on a real device
- [ ] macOS target builds on the release Xcode version
- [ ] tvOS target builds on the release Xcode version
- [ ] visionOS target builds on the release Xcode version
- [ ] Watch target builds on simulator
- [ ] Watch target runs with the paired iPhone app
- [ ] Private guide setup succeeds on a real device
- [ ] Memory behavior is acceptable after enabling the private guide

## Content checks

- [ ] `python3 Scripts/validate_content.py` passes
- [ ] Featured entries have good summaries and taste notes
- [ ] Related entries do not point to missing items
- [ ] Watch content looks sensible when loaded from bundled JSON

## App Store / review checks

- [ ] App name, subtitle, and description are up to date
- [ ] Review notes mention the watch companion app and optional private guide
- [ ] Privacy wording matches actual app behavior
- [ ] No placeholder images or fake loading states remain

## Cleanliness

- [ ] No signing secrets or local credentials are in Git diff
- [ ] No local machine junk files are staged
- [ ] Bundle identifiers and App Group values are intentional for the release build
- [ ] macOS release signing uses the sandboxed entitlements file
- [ ] tvOS release signing uses the shared app identifier and App Group entitlement
- [ ] visionOS release signing uses the shared app identifier and App Group entitlement
