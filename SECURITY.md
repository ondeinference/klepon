# Security Policy

## Supported scope

This repository is an open-source iOS application project.

Security-sensitive areas include:

- on-device model cache handling
- app sandbox / App Group configuration
- entitlements and signing setup
- accidental token or credential commits
- third-party dependency changes

## Reporting a vulnerability

If you believe you found a security issue:

1. avoid posting exploit details in a public issue immediately
2. provide a minimal reproduction and affected files
3. give maintainers reasonable time to triage before wider disclosure

## What not to commit

Never commit:

- Hugging Face tokens
- API keys
- App Store Connect keys
- private keys or certificates
- provisioning profiles
- local-only xcconfig files with secrets
- `.env` files with credentials

## Local development guidance

- use local-only config for secrets
- keep signing identities and provisioning material outside source control
- replace shared App Group or bundle identifiers with values you control if you are running your own fork
