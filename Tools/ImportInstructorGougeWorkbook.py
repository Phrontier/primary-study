#!/usr/bin/env python3

import argparse
import json
import re
import sys
import zipfile
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional
from xml.etree import ElementTree as ET


NS = {
    "a": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}

NAME_SHAPE = re.compile(r"^[A-Za-z][A-Za-z .,'?-]*(?:,\s*[A-Za-z][A-Za-z .'-]*)?$")

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_WORKBOOK = Path.home() / "Downloads" / "Instructor Gouge 3.1 (TW4).xlsx"
DEFAULT_OUTPUT = ROOT / "Primary Gouge" / "AppContent" / "InstructorReviewSeedBase.json"
DEFAULT_OVERRIDES_OUTPUT = ROOT / "Primary Gouge" / "AppContent" / "InstructorReviewSeedOverrides.json"

RANK_PREFIXES = [
    r"^maj/\s*l?cdr\s+",
    r"^ltcol\s+",
    r"^l?cdr\(?\?\)?\s+",
    r"^cdr\s+",
    r"^lcdr\s+",
    r"^capt\.?\s+",
    r"^cpt\s+",
    r"^maj\.?\s+",
    r"^lt\.?\s+",
    r"^mr\.?\s+",
    r"^mrs\.?\s+",
]

AMBIGUOUS_NAME_MARKERS = {
    "ay",
    "retired",
    "new",
    "needs name",
    "conflicting names and info",
}

NAME_EXCLUSIONS = (
    "needs name",
    "conflicting",
    "no name when trying",
    "mustve",
    "deleted it",
)

EVENT_PATTERNS = [
    re.compile(r"\b[CFIN]\s?\d{4}(?:[-/]\d{1,4})?(?:/\d{1,4})?\b", re.IGNORECASE),
    re.compile(r"\bcontacts?\b", re.IGNORECASE),
    re.compile(r"\bform checkride\b", re.IGNORECASE),
    re.compile(r"\bfams?\b", re.IGNORECASE),
    re.compile(r"\baero(?:\s+o/i)?\b", re.IGNORECASE),
    re.compile(r"\bvnav o/i\b", re.IGNORECASE),
    re.compile(r"\bday nav\b", re.IGNORECASE),
    re.compile(r"\bon[- ]?wing\b", re.IGNORECASE),
    re.compile(r"\binstrument flight\b", re.IGNORECASE),
    re.compile(r"\bep sim\b", re.IGNORECASE),
]

FLIGHT_SQUADRON = "vt-27"
SIM_SQUADRON = "tw-4"
SEED_DATE_START = datetime(2026, 3, 1, 15, 0, tzinfo=timezone.utc)
MAX_REVIEWS_PER_INSTRUCTOR = 2

MANUAL_DEMO_REVIEWS = [
    {
        "id": "seed-pending-bazemore-001",
        "instructorName": "Bazemore, Dennis",
        "squadronID": "tw-4",
        "eventName": "I3202",
        "eventKind": "sim",
        "chillScore": 6,
        "gradingScore": 5,
        "reviewText": "Great teaching energy and a calm sim environment overall, but this one needs moderation because the write-up references another student by name and should be cleaned before it goes public.",
        "submittedAt": "2026-03-28T15:00:00Z",
        "status": "pending",
    },
    {
        "id": "seed-pending-melonas-001",
        "instructorName": "Melonas, Nikko",
        "squadronID": "vt-27",
        "eventName": "I4104",
        "eventKind": "flight",
        "chillScore": 4,
        "gradingScore": 4,
        "reviewText": "Useful event notes and solid context, but the wording is still rough and too close to a direct copy of the original gouge source. Leaving it pending until it is rewritten more cleanly.",
        "submittedAt": "2026-03-25T15:00:00Z",
        "status": "pending",
    },
    {
        "id": "seed-rejected-shields-001",
        "instructorName": "Shields",
        "squadronID": "tw-4",
        "eventName": None,
        "eventKind": "sim",
        "chillScore": 2,
        "gradingScore": 2,
        "reviewText": "Rejected demo item kept for moderation coverage. This submission was too short, too personal, and did not give enough event-specific detail to be useful to other students.",
        "submittedAt": "2026-03-21T15:00:00Z",
        "status": "rejected",
    },
]


def normalize_whitespace(value: str) -> str:
    value = (value or "").replace("\u2019", "'").replace("\u201c", '"').replace("\u201d", '"').replace("\u2014", " - ")
    value = value.replace("///", " // ").replace("//", " // ")
    value = re.sub(r"\s+", " ", value)
    return value.strip(" /")


def sheet_rows(workbook_path: Path, sheet_name: str) -> list[tuple[int, dict[str, str]]]:
    with zipfile.ZipFile(workbook_path) as archive:
        strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            for item in root.findall("a:si", NS):
                strings.append("".join(text.text or "" for text in item.iterfind(".//a:t", NS)))

        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        rel_map = {relationship.attrib["Id"]: relationship.attrib["Target"] for relationship in relationships}

        target = None
        for sheet in workbook.find("a:sheets", NS):
            if sheet.attrib.get("name") == sheet_name:
                target = "xl/" + rel_map[sheet.attrib["{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"]]
                break

        if target is None:
            raise SystemExit(f"Could not find sheet named {sheet_name!r}.")

        root = ET.fromstring(archive.read(target))
        rows: list[tuple[int, dict[str, str]]] = []
        for row in root.find("a:sheetData", NS):
            values: dict[str, str] = {}
            for cell in row.findall("a:c", NS):
                reference = cell.attrib["r"]
                column = re.match(r"[A-Z]+", reference).group(0)
                cell_type = cell.attrib.get("t")
                value_node = cell.find("a:v", NS)
                inline_node = cell.find("a:is", NS)
                value = ""
                if cell_type == "s" and value_node is not None:
                    value = strings[int(value_node.text)]
                elif cell_type == "inlineStr" and inline_node is not None:
                    value = "".join(text.text or "" for text in inline_node.iterfind(".//a:t", NS))
                elif value_node is not None:
                    value = value_node.text or ""

                if value.strip():
                    values[column] = value.strip()

            if values:
                rows.append((int(row.attrib["r"]), values))

        return rows


def smart_title(value: str) -> str:
    words = []
    for part in value.split(" "):
        if part.isupper():
            words.append(part.title())
        else:
            words.append(part)
    return " ".join(words)


def normalize_name(value: str) -> Optional[str]:
    value = normalize_whitespace(value)
    lower = value.lower()
    if not value or any(marker in lower for marker in NAME_EXCLUSIONS):
        return None

    for prefix in RANK_PREFIXES:
        value = re.sub(prefix, "", value, flags=re.IGNORECASE)

    value = re.sub(r"\(\?\)", "", value)
    value = re.sub(r"\((?:pronounced:[^)]+)\)", "", value, flags=re.IGNORECASE)
    value = value.replace(" ,", ",").replace("  ", " ").strip(" ,/")
    if not value:
        return None

    value = smart_title(value)
    if not NAME_SHAPE.match(value):
        return None
    if value.lower() in AMBIGUOUS_NAME_MARKERS:
        return None

    alpha = re.sub(r"[^A-Za-z]", "", value)
    if len(alpha) < 3:
        return None

    return value


def extract_event_name(raw_event: str, review_text: str) -> Optional[str]:
    candidate = normalize_whitespace(raw_event)
    if candidate:
        candidate = re.sub(r",\s*\d{1,2}[A-Z]{3}\d{2,4}$", "", candidate)
        candidate = candidate.replace("Onng", "On-wing").replace("On ng", "On-wing")
        if candidate.upper() not in {"C", "NEW"}:
            return candidate

    for pattern in EVENT_PATTERNS:
        match = pattern.search(review_text)
        if match:
            found = normalize_whitespace(match.group(0))
            found = found.replace("Onng", "On-wing").replace("On ng", "On-wing")
            return found

    return None


def chill_score_from_label(label: Optional[str], review_text: str) -> int:
    text = f"{label or ''} {review_text}".lower()

    if any(token in text for token in ["game over", "asshole", "nightmare", "unchill/gg", "not chill /", "single most unchill"]):
        return 1
    if any(token in text for token in ["not chill", "below average chill", "not that chill", "deceptively chill", "intense", "degrading"]):
        return 2
    if any(token in text for token in ["moderately chill in the air", "serious", "firm but fair", "healthy standard", "tense"]):
        return 3
    if any(token in text for token in ["moderately chill", "mid chill", "average chill", "neutral", "standard chill"]):
        return 4
    if any(token in text for token in ["pretty chill", "chill af", "laid back", "easy going", "mostly chill", "chill"]):
        return 5
    if any(token in text for token in ["very chill", "super chill", "extremely chill", "biggggg chillin", "too chill"]):
        return 6
    if any(token in text for token in ["chillmaster", "chillionaire", "chill goblin", "prime minister of chill", "bob ross", "chiller of the universe", "chilltacular"]):
        return 7
    return 4


def grading_score_from_text(review_text: str) -> int:
    text = review_text.lower()
    score = 4

    positive = {
        3: ["grades insanely well", "straight 4's", "above mif for just about everything", "drag the mouse cursor straight down the 4 column"],
        2: ["easy grader", "incredibly generous", "generous with grades", "good grades", "grades very well", "very fair grader", "fair to generous"],
        1: ["fair grader", "grades well", "good grader", "decent grade", "fair overall", "grades to performance", "follows cts", "by the book", "average grader"],
    }
    negative = {
        -1: ["tough grader", "strict", "rigid", "underwhelming grades", "not easy on grades", "fair/tough", "graded low"],
        -2: ["harsh grader", "grades low", "mif you out", "straight mif", "mif across the board", "borderline items broke against me"],
        -3: ["mif monster", "game over", "received 3s", "fail me", "failed me"],
    }

    for delta, phrases in positive.items():
        if any(phrase in text for phrase in phrases):
            score += delta
    for delta, phrases in negative.items():
        if any(phrase in text for phrase in phrases):
            score += delta

    return max(1, min(7, score))


def parse_ip_reviews(workbook_path: Path) -> list[dict]:
    rows = sheet_rows(workbook_path, "IPs")
    reviews = []
    current = None

    for row_number, values in rows:
        if row_number == 1:
            continue

        if "B" in values:
            name = normalize_name(values.get("B", ""))
            current = None
            if name:
                current = {
                    "name": name,
                    "event": normalize_whitespace(values.get("H", "")),
                    "chill": normalize_whitespace(values.get("G", "")),
                }

        if not current:
            continue

        review_text = normalize_whitespace(values.get("I", ""))
        if len(review_text) < 60:
            continue

        event_name = extract_event_name(values.get("H", "") or current["event"], review_text)
        chill_label = normalize_whitespace(values.get("G", "") or current["chill"])
        reviews.append(
            {
                "kind": "flight",
                "squadronID": FLIGHT_SQUADRON,
                "instructorName": current["name"],
                "eventName": event_name,
                "eventKind": "flight",
                "chillScore": chill_score_from_label(chill_label, review_text),
                "gradingScore": grading_score_from_text(review_text),
                "reviewText": review_text,
                "sourceRow": row_number,
            }
        )

    return reviews


def sim_name_from_row(values: dict[str, str]) -> Optional[str]:
    candidates = []
    for column in ("A", "B"):
        candidate = normalize_name(values.get(column, ""))
        if candidate:
            candidates.append(candidate)

    extra_name = normalize_name(values.get("D", ""))
    if extra_name and candidates and extra_name != candidates[0]:
        return None

    unique_candidates = list(dict.fromkeys(candidates))
    if len(unique_candidates) != 1:
        return None

    return unique_candidates[0]


def parse_sim_reviews(workbook_path: Path) -> list[dict]:
    rows = sheet_rows(workbook_path, "Sim Instructors")
    reviews = []
    current = None

    for row_number, values in rows:
        name = sim_name_from_row(values)
        if name is not None:
            current = {
                "name": name,
                "chill": normalize_whitespace(values.get("D", "")),
            }
        elif values.get("A", "").strip() or values.get("B", "").strip():
            current = None
        elif "D" in values:
            joined = values.get("D", "").lower()
            if any(marker in joined for marker in NAME_EXCLUSIONS):
                current = None

        if not current:
            continue

        review_text = normalize_whitespace(values.get("E", ""))
        if len(review_text) < 60:
            continue

        event_name = extract_event_name("", review_text)
        chill_label = normalize_whitespace(values.get("D", "") or current["chill"])
        reviews.append(
            {
                "kind": "sim",
                "squadronID": SIM_SQUADRON,
                "instructorName": current["name"],
                "eventName": event_name,
                "eventKind": "sim",
                "chillScore": chill_score_from_label(chill_label, review_text),
                "gradingScore": grading_score_from_text(review_text),
                "reviewText": review_text,
                "sourceRow": row_number,
            }
        )

    return reviews


def select_reviews(parsed_reviews: list[dict]) -> list[dict]:
    grouped: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    for review in parsed_reviews:
        grouped[(review["kind"], review["squadronID"], review["instructorName"])].append(review)

    selected = []
    for key, reviews in grouped.items():
        reviews.sort(key=lambda review: (review["eventName"] is None, -len(review["reviewText"]), review["sourceRow"]))
        for review in reviews[:MAX_REVIEWS_PER_INSTRUCTOR]:
            selected.append(review)

    selected.sort(key=lambda review: (review["kind"], review["instructorName"], review["sourceRow"]))
    return selected


def attach_ids_and_dates(reviews: list[dict]) -> list[dict]:
    seeded = []
    for index, review in enumerate(reviews, start=1):
        slug = re.sub(r"[^a-z0-9]+", "-", review["instructorName"].lower()).strip("-")
        seeded.append(
            {
                "id": f"seed-{review['kind']}-{slug}-{index:03d}",
                "instructorName": review["instructorName"],
                "squadronID": review["squadronID"],
                "eventName": review["eventName"],
                "eventKind": review["eventKind"],
                "chillScore": review["chillScore"],
                "gradingScore": review["gradingScore"],
                "reviewText": review["reviewText"],
                "submittedAt": (SEED_DATE_START - timedelta(days=index)).isoformat().replace("+00:00", "Z"),
                "status": "approved",
            }
        )
    return seeded


def render_base_json(seed_reviews: list[dict], workbook_path: Path) -> str:
    payload = {
        "sourceWorkbook": str(workbook_path),
        "generatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "reviews": seed_reviews + MANUAL_DEMO_REVIEWS,
    }
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def ensure_override_file(path: Path) -> None:
    if path.exists():
        return

    payload = {
        "overrides": []
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Import instructor gouge workbook into the editable AppContent JSON seed files.")
    parser.add_argument("--workbook", type=Path, default=DEFAULT_WORKBOOK)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--overrides-output", type=Path, default=DEFAULT_OVERRIDES_OUTPUT)
    args = parser.parse_args()

    if not args.workbook.exists():
        raise SystemExit(f"Workbook not found at {args.workbook}")

    parsed = parse_ip_reviews(args.workbook) + parse_sim_reviews(args.workbook)
    selected = select_reviews(parsed)
    seeded = attach_ids_and_dates(selected)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    base_json = render_base_json(seeded, args.workbook)
    args.output.write_text(base_json, encoding="utf-8")
    ensure_override_file(args.overrides_output)

    flight_count = sum(1 for item in seeded if item["eventKind"] == "flight")
    sim_count = sum(1 for item in seeded if item["eventKind"] == "sim")
    unique_instructors = len({(item["squadronID"], item["instructorName"]) for item in seeded})
    print(f"Wrote {len(seeded)} approved seed reviews for {unique_instructors} instructors.")
    print(f"Flight reviews: {flight_count}")
    print(f"Sim reviews: {sim_count}")
    print(f"Base JSON: {args.output}")
    print(f"Overrides JSON: {args.overrides_output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
