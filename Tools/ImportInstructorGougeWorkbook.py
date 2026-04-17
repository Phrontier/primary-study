#!/usr/bin/env python3

import argparse
import csv
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
WORD_NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

NAME_SHAPE = re.compile(r"^[A-Za-z][A-Za-z .,'?-]*(?:,\s*[A-Za-z][A-Za-z .'-]*)?$")

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_WORKBOOK = Path.home() / "Downloads" / "Instructor Gouge 3.1 (TW4).xlsx"
DEFAULT_VT28_CSV = Path.home() / "Downloads" / "Ranger IP Gouge - Ranger IP Gouge.csv"
DEFAULT_TW5_DOCX = Path.home() / "Downloads" / "North Whiting Sim Instructors.docx"
DEFAULT_OUTPUT = ROOT / "Primary Gouge" / "AppContent" / "InstructorReviewSeedBase.json"
DEFAULT_OVERRIDES_OUTPUT = ROOT / "Primary Gouge" / "AppContent" / "InstructorReviewSeedOverrides.json"
STUDY_MANIFEST_PATH = ROOT / "Primary Gouge" / "AppContent" / "StudyManifest.json"

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
VT28_FLIGHT_SQUADRON = "vt-28"
TW5_SIM_SQUADRON = "tw-5"
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

EVENT_CODE_PATTERN = re.compile(r"\b(FAM|CS|I|F|N|C)\s*-?\s*(\d{4})\b", re.IGNORECASE)
EVENT_FAMILY_PATTERN = re.compile(r"\b(FAM|CS|I|F|N|C)\s*-?\s*(\d{2})(?:XX|X)?\b", re.IGNORECASE)
SIM_EVENT_CODE_PATTERN = re.compile(r"\b(FAM|I|C)\s*-?\s*(\d{4})\b", re.IGNORECASE)
SIM_EVENT_FAMILY_PATTERN = re.compile(r"\b(FAM|I|C)\s*-?\s*(\d{2})(?:XX|X)?\b", re.IGNORECASE)

DOCX_STOP_MARKERS = {
    "regardless of who your instructor is:",
    "general",
    "eps",
    "basic instruments",
    "instruments",
}

DOCX_NOISE_LINES = {
    "north whiting sim instructors",
    "**their pictures/info at the end",
    "***general info after the instructor pictures",
    "air force",
    "g.o.a.t.",
    "yes",
    "chiller",
}

DOCX_NON_NAME_PHRASES = {
    "grades fairly",
    "he's the man",
    "weird dude",
}

DOCX_NON_NAME_TOKENS = {
    "grades",
    "fairly",
    "he's",
    "weird",
    "dude",
    "awesome",
    "great",
    "nice",
    "super",
    "favorite",
    "agree",
}


def load_manifest_event_codes(kind: str) -> list[str]:
    try:
        manifest = json.loads(STUDY_MANIFEST_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return []

    events: list[str] = []
    for phase in manifest.get("phases", []):
        for category in phase.get("categories", []):
            if category.get("kind") != kind:
                continue
            for event in category.get("events", []):
                code = re.sub(r"\s+", " ", (event.get("code", "") or "")).strip().upper()
                if code:
                    events.append(code)

    return list(dict.fromkeys(events))


FLIGHT_EVENT_CODES = load_manifest_event_codes("flights")
FLIGHT_EVENT_CODE_SET = set(FLIGHT_EVENT_CODES)
SIM_EVENT_CODES = load_manifest_event_codes("sims")
SIM_EVENT_CODE_SET = set(SIM_EVENT_CODES)


def build_first_event_by_family(codes: list[str]) -> dict[tuple[str, str], str]:
    families: dict[tuple[str, str], str] = {}
    for code in codes:
        match = re.match(r"^([A-Z]+)(\d{2})\d{2}$", code)
        if match is None:
            continue
        key = (match.group(1), match.group(2))
        families.setdefault(key, code)
    return families


FIRST_EVENT_BY_FAMILY = build_first_event_by_family(FLIGHT_EVENT_CODES)
SIM_FIRST_EVENT_BY_FAMILY = build_first_event_by_family(SIM_EVENT_CODES)


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


def docx_paragraphs(source: Path) -> list[tuple[int, str]]:
    with zipfile.ZipFile(source) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))

    paragraphs: list[tuple[int, str]] = []
    for index, paragraph in enumerate(root.findall(".//w:p", WORD_NS), start=1):
        text = "".join(node.text or "" for node in paragraph.findall(".//w:t", WORD_NS))
        normalized = normalize_whitespace(text)
        if normalized:
            paragraphs.append((index, normalized))

    return paragraphs


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

    value = value.replace("“", "").replace("”", "").replace('"', "")
    value = re.sub(r"\(\?\)", "", value)
    value = re.sub(r"\((?:pronounced:[^)]+)\)", "", value, flags=re.IGNORECASE)
    value = re.sub(r"\(([^)]+)\)", r" \1 ", value)
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


def normalized_name_key(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def normalized_name_tokens(value: str) -> tuple[str, ...]:
    return tuple(sorted(token for token in re.split(r"[^A-Za-z0-9]+", value.lower()) if token))


def surname_key(value: str) -> str:
    cleaned = normalize_whitespace(value).lower()
    if "," in cleaned:
        cleaned = cleaned.split(",", 1)[0]
    else:
        parts = [part for part in re.split(r"[^A-Za-z0-9]+", cleaned) if part]
        cleaned = parts[-1] if parts else ""
    return re.sub(r"[^a-z0-9]+", "", cleaned)


def build_canonical_name_lookup(reviews: list[dict]) -> tuple[dict[str, str], dict[tuple[str, ...], str], dict[str, str]]:
    exact_lookup: dict[str, str] = {}
    token_candidates: dict[tuple[str, ...], set[str]] = defaultdict(set)
    surname_candidates: dict[str, set[str]] = defaultdict(set)

    for review in reviews:
        name = review["instructorName"]
        exact_lookup[normalized_name_key(name)] = name
        token_candidates[normalized_name_tokens(name)].add(name)
        surname_candidates[surname_key(name)].add(name)

    token_lookup = {
        tokens: next(iter(names))
        for tokens, names in token_candidates.items()
        if len(names) == 1
    }
    surname_lookup = {
        key: next(iter(names))
        for key, names in surname_candidates.items()
        if len(names) == 1
    }
    return exact_lookup, token_lookup, surname_lookup


def canonicalize_name(
    raw_name: str,
    exact_lookup: dict[str, str],
    token_lookup: dict[tuple[str, ...], str],
    surname_lookup: dict[str, str],
) -> Optional[str]:
    normalized = normalize_name(raw_name)
    if normalized is None:
        return None

    exact = exact_lookup.get(normalized_name_key(normalized))
    if exact is not None:
        return exact

    token_match = token_lookup.get(normalized_name_tokens(normalized))
    if token_match is not None:
        return token_match

    if len(normalized_name_tokens(normalized)) == 1:
        surname_match = surname_lookup.get(surname_key(normalized))
        if surname_match is not None:
            return surname_match

    return normalized


def docx_name_candidate(value: str) -> Optional[str]:
    normalized = normalize_whitespace(value).rstrip(":").rstrip("-")
    lower = normalized.lower()

    if lower in DOCX_NOISE_LINES or lower in DOCX_NON_NAME_PHRASES or lower.startswith("*"):
        return None
    if any(marker in lower for marker in DOCX_STOP_MARKERS):
        return None
    if any(char.isdigit() for char in normalized):
        return None
    if len(normalized) > 48:
        return None
    if normalized.count(",") > 1:
        return None

    token_count = len([token for token in re.split(r"\s+", normalized) if token])
    if token_count == 0 or token_count > 4:
        return None
    lower_tokens = [token for token in re.split(r"[^a-z']+", lower) if token]
    if any(token in DOCX_NON_NAME_TOKENS for token in lower_tokens):
        return None

    if re.search(r"[.!?]", normalized):
        return None
    if normalized.lower() != smart_title(normalized).lower():
        return None

    return normalize_name(normalized)


def paragraph_looks_like_review(text: str) -> bool:
    lowered = text.lower()

    if lowered in DOCX_NOISE_LINES or any(lowered == marker for marker in DOCX_STOP_MARKERS):
        return False

    keyword_patterns = [
        r"\bgrade",
        r"\bgrader",
        r"\bbrief",
        r"\bdebrief",
        r"\bsim",
        r"\binstructor",
        r"\bteach",
        r"\bhelp",
        r"\bchill",
        r"\bfair",
        r"\bstrict",
        r"\bharsh",
        r"\bnice",
        r"\bquestions?",
        r"\bprepared",
        r"\bprocedure",
        r"\bmif",
        r"\bunsat",
    ]

    if len(text) >= 45 or len(text.split()) >= 8:
        return True

    return any(re.search(pattern, lowered) for pattern in keyword_patterns)


def normalize_event_text(value: str) -> str:
    normalized = normalize_whitespace(value).upper()
    normalized = normalized.replace("&", "/")
    normalized = normalized.replace(" ", "")
    return normalized


def canonical_event_from_segment(segment: str) -> Optional[str]:
    normalized = normalize_event_text(segment)
    if not normalized:
        return None

    if re.search(r"ON-?WING", normalized):
        return "FAM4101"

    for match in EVENT_CODE_PATTERN.finditer(normalized):
        code = f"{match.group(1).upper()}{match.group(2)}"
        if code in FLIGHT_EVENT_CODE_SET:
            return code

    for match in EVENT_FAMILY_PATTERN.finditer(normalized):
        prefix = match.group(1).upper()
        block = match.group(2)
        first_event = FIRST_EVENT_BY_FAMILY.get((prefix, block))
        if first_event is not None:
            return first_event

    return None


def extract_vt28_event_name(raw_event: str, review_text: str) -> Optional[str]:
    for candidate in (raw_event, review_text):
        code = canonical_event_from_segment(candidate)
        if code is not None:
            return code

    return None


def canonical_sim_event_from_segment(segment: str) -> Optional[str]:
    normalized = normalize_event_text(segment)
    if not normalized:
        return None

    for match in SIM_EVENT_CODE_PATTERN.finditer(normalized):
        code = f"{match.group(1).upper()}{match.group(2)}"
        if code in SIM_EVENT_CODE_SET:
            return code

    for match in SIM_EVENT_FAMILY_PATTERN.finditer(normalized):
        prefix = match.group(1).upper()
        block = match.group(2)
        first_event = SIM_FIRST_EVENT_BY_FAMILY.get((prefix, block))
        if first_event is not None:
            return first_event

    return None


def extract_tw5_event_name(paragraph: str) -> Optional[str]:
    return canonical_sim_event_from_segment(paragraph)


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
    if any(token in text for token in ["blizzard", "bring a parka", "ice water at 2am chill", "nuclear winter chill", "tactical imsafe", "helmet fire", "trip you up", "aggressive", "not chill", "below average chill", "not that chill", "deceptively chill", "intense", "degrading"]):
        return 2
    if any(token in text for token in ["chill until not", "moderately chill in the air", "serious", "firm but fair", "healthy standard", "tense"]):
        return 3
    if any(token in text for token in ["moderately chill", "mid chill", "average chill", "neutral", "standard chill"]):
        return 4
    if any(token in text for token in ["pretty chill", "chill/goofy", "goofy", "super nice", "easygoing", "easy going", "chill af", "laid back", "mostly chill", "chill"]):
        return 5
    if any(token in text for token in ["straight chiller", "very relaxed", "very chilly", "very chill", "superchill", "super chill", "extremely chill", "beyond chill", "biggggg chillin", "too chill"]):
        return 6
    if any(token in text for token in ["chillmaster", "chillionaire", "bob ross chill", "chill goblin", "prime minister of chill", "bob ross", "chiller of the universe", "chilltacular"]):
        return 7
    return 4


def grading_score_from_text(review_text: str) -> int:
    text = review_text.lower()
    score = 4

    positive = {
        3: ["santa claus", "grades insanely well", "straight 4's", "above mif for just about everything", "drag the mouse cursor straight down the 4 column"],
        2: ["easy grader", "incredibly generous", "generous grader", "generous with grades", "good grades", "grades very well", "very fair grader", "fair to generous"],
        1: ["fair grader", "grades well", "good grader", "decent grade", "fair overall", "grades to performance", "follows cts", "by the book", "average grader"],
    }
    negative = {
        -1: ["honest grader", "tough grader", "strict", "rigid", "underwhelming grades", "not easy on grades", "fair/tough", "graded low"],
        -2: ["mif monster", "harsh grader", "grades low", "mif you out", "straight mif", "mif across the board", "borderline items broke against me"],
        -3: ["game over", "received 3s", "fail me", "failed me"],
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


def parse_vt28_csv_reviews(
    csv_path: Path,
    exact_lookup: dict[str, str],
    token_lookup: dict[tuple[str, ...], str],
    surname_lookup: dict[str, str],
) -> list[dict]:
    if not csv_path.exists():
        return []

    rows: list[dict] = []
    with csv_path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.reader(handle)
        for row_number, row in enumerate(reader, start=1):
            padded = row + [""] * max(0, 9 - len(row))
            marker, name, _, chill_label, raw_event, *comments = padded

            if row_number <= 2:
                continue

            normalized_name = canonicalize_name(name, exact_lookup, token_lookup, surname_lookup)
            if normalized_name is None:
                continue

            if marker.strip().lower().startswith("ex.") or normalized_name == "John, Smith":
                continue

            event_name = extract_vt28_event_name(raw_event, " ".join(comments))

            for comment_index, comment in enumerate(comments, start=1):
                review_text = normalize_whitespace(comment)
                if not review_text:
                    continue

                rows.append(
                    {
                        "kind": "flight",
                        "source": "vt28_csv",
                        "sourceRow": row_number,
                        "sourceCommentIndex": comment_index,
                        "squadronID": VT28_FLIGHT_SQUADRON,
                        "instructorName": normalized_name,
                        "eventName": event_name,
                        "eventKind": "flight",
                        "chillScore": chill_score_from_label(chill_label, review_text),
                        "gradingScore": grading_score_from_text(review_text),
                        "reviewText": review_text,
                    }
                )

    return rows


def parse_tw5_docx_reviews(
    docx_path: Path,
    exact_lookup: dict[str, str],
    token_lookup: dict[tuple[str, ...], str],
    surname_lookup: dict[str, str],
) -> list[dict]:
    if not docx_path.exists():
        return []

    reviews: list[dict] = []
    current_instructor: Optional[str] = None

    for paragraph_index, paragraph in docx_paragraphs(docx_path):
        lowered = paragraph.lower()
        if lowered in DOCX_STOP_MARKERS:
            break

        possible_name = docx_name_candidate(paragraph)
        if possible_name is not None:
            canonical_name = canonicalize_name(possible_name, exact_lookup, token_lookup, surname_lookup)
            if canonical_name is None:
                continue
            if len(normalized_name_tokens(possible_name)) == 1 and len(normalized_name_tokens(canonical_name)) == 1:
                continue
            current_instructor = canonical_name
            continue

        if current_instructor is None:
            continue

        if not paragraph_looks_like_review(paragraph):
            continue

        reviews.append(
            {
                "kind": "sim",
                "source": "tw5_docx",
                "sourceRow": paragraph_index,
                "squadronID": TW5_SIM_SQUADRON,
                "instructorName": current_instructor,
                "eventName": extract_tw5_event_name(paragraph),
                "eventKind": "sim",
                "chillScore": chill_score_from_label(None, paragraph),
                "gradingScore": grading_score_from_text(paragraph),
                "reviewText": paragraph,
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


def sort_reviews_for_seeding(reviews: list[dict]) -> list[dict]:
    return sorted(
        reviews,
        key=lambda review: (
            review["kind"],
            review["squadronID"],
            review["instructorName"],
            review.get("sourceRow", 0),
            review.get("sourceCommentIndex", 0),
            review.get("eventName") or "",
            review["reviewText"],
        ),
    )


def attach_ids_and_dates(reviews: list[dict], start_index: int = 1) -> list[dict]:
    seeded = []
    for index, review in enumerate(reviews, start=start_index):
        slug = re.sub(r"[^a-z0-9]+", "-", review["instructorName"].lower()).strip("-")
        review_id = review.get("seedID")
        if review_id is None:
            review_id = f"seed-{review['kind']}-{slug}-{index:03d}"
        seeded.append(
            {
                "id": review_id,
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


def render_base_json(seed_reviews: list[dict], workbook_path: Path, csv_path: Optional[Path], docx_path: Optional[Path]) -> str:
    source_parts = [str(workbook_path)]
    if csv_path is not None and csv_path.exists():
        source_parts.append(str(csv_path))
    if docx_path is not None and docx_path.exists():
        source_parts.append(str(docx_path))

    payload = {
        "sourceWorkbook": " | ".join(source_parts),
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
    parser.add_argument("--vt28-csv", type=Path, default=DEFAULT_VT28_CSV)
    parser.add_argument("--tw5-docx", type=Path, default=DEFAULT_TW5_DOCX)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--overrides-output", type=Path, default=DEFAULT_OVERRIDES_OUTPUT)
    args = parser.parse_args()

    if not args.workbook.exists():
        raise SystemExit(f"Workbook not found at {args.workbook}")

    parsed_workbook = parse_ip_reviews(args.workbook) + parse_sim_reviews(args.workbook)
    exact_lookup, token_lookup, surname_lookup = build_canonical_name_lookup(parsed_workbook)
    parsed_vt28_csv = parse_vt28_csv_reviews(args.vt28_csv, exact_lookup, token_lookup, surname_lookup)
    combined_for_lookup = parsed_workbook + parsed_vt28_csv
    exact_lookup, token_lookup, surname_lookup = build_canonical_name_lookup(combined_for_lookup)
    parsed_tw5_docx = parse_tw5_docx_reviews(args.tw5_docx, exact_lookup, token_lookup, surname_lookup)

    selected_workbook = select_reviews(parsed_workbook)
    seeded_workbook = attach_ids_and_dates(selected_workbook)

    selected_vt28_csv = sort_reviews_for_seeding(parsed_vt28_csv)
    for review in selected_vt28_csv:
        slug = re.sub(r"[^a-z0-9]+", "-", review["instructorName"].lower()).strip("-")
        review["seedID"] = (
            f"seed-flight-vt28-{slug}-csv-r{review['sourceRow']}-c{review['sourceCommentIndex']}"
        )

    seeded_vt28_csv = attach_ids_and_dates(selected_vt28_csv, start_index=len(seeded_workbook) + 1)
    selected_tw5_docx = sort_reviews_for_seeding(parsed_tw5_docx)
    for review in selected_tw5_docx:
        slug = re.sub(r"[^a-z0-9]+", "-", review["instructorName"].lower()).strip("-")
        review["seedID"] = f"seed-sim-tw5-{slug}-docx-p{review['sourceRow']}"

    seeded_tw5_docx = attach_ids_and_dates(
        selected_tw5_docx,
        start_index=len(seeded_workbook) + len(seeded_vt28_csv) + 1,
    )
    seeded = seeded_workbook + seeded_vt28_csv + seeded_tw5_docx
    args.output.parent.mkdir(parents=True, exist_ok=True)
    base_json = render_base_json(seeded, args.workbook, args.vt28_csv, args.tw5_docx)
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
