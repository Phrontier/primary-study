#!/usr/bin/env python3

import json
import re
from collections import OrderedDict
from pathlib import Path
from typing import Optional


ROOT = Path(__file__).resolve().parent.parent
LIBRARY_PATH = ROOT / "Primary Gouge" / "AppContent" / "FlashcardLibrary.json"
OVERRIDES_DIR = ROOT / "Primary Gouge" / "AppContent" / "EventContentOverrides"
OUTPUT_PATH = ROOT / "Primary Gouge" / "AppContent" / "FlashcardsByEvent.json"


def normalize_code(value: str) -> str:
    return value.replace(" ", "")


def nonempty(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    stripped = value.strip()
    return stripped or None


def main() -> None:
    library = json.loads(LIBRARY_PATH.read_text())["flashcards"]
    override_metadata: dict[str, dict[str, str]] = {}
    valid_event_codes = set()

    for path in ROOT.joinpath("Contents").rglob("*"):
        if not path.is_file():
            continue
        for pattern in (r"[A-Z]{1,4}\s?\d{4}", r"CS\s?\d{4}"):
            match = re.search(pattern, path.name)
            if match:
                valid_event_codes.add(normalize_code(match.group(0)))

    for path in sorted(OVERRIDES_DIR.glob("*.json")):
        data = json.loads(path.read_text())
        code = normalize_code(data["code"])
        valid_event_codes.add(code)
        metadata: dict[str, str] = {}
        if title := nonempty(data.get("flashcardDeckTitle")):
            metadata["deckTitle"] = title
        if summary := nonempty(data.get("flashcardDeckSummary")):
            metadata["deckSummary"] = summary
        if metadata:
            override_metadata[code] = metadata

    sections: "OrderedDict[str, OrderedDict[str, object]]" = OrderedDict()
    library_cards = []

    for card in library:
        raw_event_codes = [normalize_code(code) for code in card.get("eventCodes", []) if code]
        event_codes = [code for code in raw_event_codes if code in valid_event_codes]
        card_entry = OrderedDict()
        card_entry["id"] = card["id"]
        card_entry["prompt"] = card["prompt"]
        card_entry["answer"] = card["answer"]

        tags = card.get("tags") or []
        if tags:
            card_entry["tags"] = tags

        categories = card.get("studyCategories") or []
        if categories:
            card_entry["studyCategories"] = categories

        kind = card.get("kind")
        if kind and kind != "standard":
            card_entry["kind"] = kind

        if not event_codes:
            library_cards.append(card_entry)
            continue

        home_code = event_codes[0]
        section = sections.setdefault(home_code, OrderedDict())
        section.setdefault("cards", [])

        also_include = event_codes[1:]
        if also_include:
            card_entry["alsoIncludeInEvents"] = also_include

        section["cards"].append(card_entry)

    for code, metadata in override_metadata.items():
        section = sections.setdefault(code, OrderedDict())
        for key, value in metadata.items():
            section[key] = value
        section.setdefault("cards", [])

    ordered_events = OrderedDict()
    for code in sorted(sections):
        source_section = sections[code]
        output_section = OrderedDict()
        if "deckTitle" in source_section:
            output_section["deckTitle"] = source_section["deckTitle"]
        if "deckSummary" in source_section:
            output_section["deckSummary"] = source_section["deckSummary"]
        output_section["cards"] = source_section.get("cards", [])
        ordered_events[code] = output_section

    output = OrderedDict([("events", ordered_events)])
    if library_cards:
        output["libraryCards"] = library_cards
    OUTPUT_PATH.write_text(json.dumps(output, indent=2) + "\n")
    print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
