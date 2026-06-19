#!/bin/sh
set -eu

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPO_ROOT"
swift "$REPO_ROOT/Scripts/generate_tvos_brand_assets.swift" "$@"
