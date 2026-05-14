# Release checklist

## Before tagging

- [ ] iPhone app builds cleanly
- [ ] watchOS companion builds cleanly
- [ ] README is current
- [ ] LICENSE files are present
- [ ] SECURITY.md is present
- [ ] App Store metadata in `AppStore/metadata/en-US/` is current
- [ ] Screenshots are captured and reviewed

## Product quality

- [ ] Core browse flows feel polished
- [ ] Ask flow works on device with acceptable latency
- [ ] Watch app content is readable and useful at a glance
- [ ] No obvious sample-app copy remains

## Signing and distribution

- [ ] iPhone bundle identifier is correct
- [ ] watch bundle identifier is correct
- [ ] App Group entitlement is correct for the shipping account
- [ ] Provisioning profiles and signing identities are valid

## Final gate

- [ ] TestFlight build installed on at least one real iPhone
- [ ] Watch companion installed and tested on at least one real Apple Watch
- [ ] Release notes are written
- [ ] Git status is clean before tagging
