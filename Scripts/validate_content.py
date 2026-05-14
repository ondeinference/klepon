from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIR = ROOT / "Klepon" / "Resources" / "Content"
ENTRIES_PATH = CONTENT_DIR / "guide_entries.json"
COLLECTIONS_PATH = CONTENT_DIR / "collections.json"


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)


def main() -> None:
    entries = json.loads(ENTRIES_PATH.read_text())
    collections = json.loads(COLLECTIONS_PATH.read_text())

    if not entries:
        fail("guide_entries.json is empty")

    ids = [entry["id"] for entry in entries]
    unique_ids = set(ids)

    if len(ids) != len(unique_ids):
        duplicates = sorted({entry_id for entry_id in ids if ids.count(entry_id) > 1})
        fail(f"duplicate entry ids: {', '.join(duplicates)}")

    missing_featured = not any(entry.get("isFeatured") for entry in entries)
    if missing_featured:
        fail("at least one entry must be marked isFeatured=true")

    for entry in entries:
        for field in ["id", "title", "subtitle", "summary", "story"]:
            value = entry.get(field)
            if not isinstance(value, str) or not value.strip():
                fail(f"entry {entry.get('id', '<unknown>')} has invalid field: {field}")

        for related_id in entry.get("relatedIDs", []):
            if related_id not in unique_ids:
                fail(f"entry {entry['id']} references missing related id: {related_id}")

    for collection in collections:
        if not collection.get("entryIDs"):
            fail(f"collection {collection.get('id', '<unknown>')} has no entryIDs")

        for entry_id in collection["entryIDs"]:
            if entry_id not in unique_ids:
                fail(f"collection {collection['id']} references missing entry id: {entry_id}")

    print(
        f"Content validation passed: {len(entries)} entries, {len(collections)} collections, {sum(1 for entry in entries if entry.get('isFeatured'))} featured."
    )


if __name__ == "__main__":
    main()
