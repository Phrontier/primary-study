#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from xml.etree import ElementTree as ET
from zipfile import ZipFile

NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
DOCX_HEADER_LINES = {
    "T-6B MASTER QUESTION FILE",
    "CHANGE 2 - 01 AUG 23",
    "NFM: 01 DEC 2017",
}

CATEGORY_SPECS = {
    "systems-and-procedures": {
        "title": "Systems & Procedures",
        "summary": "Engine, fuel, hydraulics, electrics, cockpit systems, and normal operating procedures.",
        "iconName": "gearshape.2.fill",
        "tags": ["systems", "procedures", "natops"],
    },
    "performance-limits-weather": {
        "title": "Performance, Limits & Weather",
        "summary": "Takeoff and landing performance, limitations, winds, icing, and operational weather knowledge.",
        "iconName": "gauge.with.needle.fill",
        "tags": ["performance", "limits", "weather", "natops"],
    },
    "emergency-procedures": {
        "title": "Emergency Procedures",
        "summary": "Ejection, airstarts, abnormal indications, oxygen, and other immediate-action knowledge.",
        "iconName": "exclamationmark.shield.fill",
        "tags": ["ep", "emergency", "natops"],
    },
    "aerodynamics-and-handling": {
        "title": "Aerodynamics & Handling",
        "summary": "Stalls, flight characteristics, configuration effects, and practical aircraft handling knowledge.",
        "iconName": "airplane",
        "tags": ["aerodynamics", "handling", "natops"],
    },
}

TOPIC_KEYWORDS = {
    "eps": ["eject", "ejection", "emergency", "airstart", "abort", "chip detector", "oxygen bottle", "fuel lo", "pmu fail"],
    "limits": ["maximum", "minimum", "limit", "crosswind", "airspeed", "torque", "psi", "volts", "knots", "n1", "np", "gust"],
    "nwc": ["do not", "warning", "warnings", "caution", "cautions", "recommend", "avoid"],
    "landing-pattern": ["landing", "runway", "final", "base", "downwind", "touchdown", "gear extension"],
    "instrument-comms": ["instrument", "ifr", "vfr", "holding", "approach", "radio", "clearance", "comms"],
    "maneuvers": ["stall", "spin", "roll-off", "glide", "maneuver", "aerobatic"],
    "systems": ["engine", "oil", "fuel", "hydraulic", "generator", "battery", "propeller", "pmu", "trim", "oxygen", "flap", "gear", "brake"],
}

OPTION_IDS = ["a", "b", "c", "d"]


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: BuildQuizBankFromDocx.py <input.docx> <output.json>", file=sys.stderr)
        return 1

    source = Path(sys.argv[1]).expanduser()
    destination = Path(sys.argv[2]).expanduser()

    quiz_bank = build_quiz_bank(source)
    destination.write_text(json.dumps(quiz_bank, indent=2), encoding="utf-8")
    print(f"Wrote {len(quiz_bank['questions'])} questions to {destination}")
    return 0


def build_quiz_bank(source: Path) -> dict:
    paragraphs = load_paragraphs(source)
    parsed_questions = parse_questions(paragraphs)

    categories = [
        {"id": category_id, **spec}
        for category_id, spec in CATEGORY_SPECS.items()
    ]

    counters: defaultdict[str, int] = defaultdict(int)
    questions = []
    for parsed in parsed_questions:
        category_id = category_id_for_reference(parsed["reference"])
        counters[category_id] += 1
        question_id = f"{category_id}-{counters[category_id]:03d}"
        format_value = question_format(parsed["options"])
        correct_text = parsed["options"][parsed["correct_index"]]
        tags = build_tags(parsed["prompt"], parsed["options"], parsed["reference"], category_id)

        if format_value == "trueFalse":
            choices = [
                {"id": "true", "text": "True"},
                {"id": "false", "text": "False"},
            ]
            correct_choice_id = "true" if correct_text.lower() == "true" else "false"
        else:
            choices = [
                {"id": OPTION_IDS[index], "text": option}
                for index, option in enumerate(parsed["options"])
            ]
            correct_choice_id = OPTION_IDS[parsed["correct_index"]]

        questions.append(
            {
                "id": question_id,
                "categoryID": category_id,
                "prompt": parsed["prompt"],
                "format": format_value,
                "choices": choices,
                "correctChoiceID": correct_choice_id,
                "explanation": f"Correct answer sourced from NATOPS Closed Bank 2025. Review reference {parsed['reference']} for the full procedure or limitation context.",
                "reference": parsed["reference"],
                "tags": tags,
            }
        )

    return {"categories": categories, "questions": questions}


def load_paragraphs(source: Path) -> list[tuple[str, list[tuple[str, bool]]]]:
    with ZipFile(source) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))

    paragraphs: list[tuple[str, list[tuple[str, bool]]]] = []
    for paragraph in root.findall(".//w:p", NS):
        runs: list[tuple[str, bool]] = []
        full_text: list[str] = []
        for run in paragraph.findall("w:r", NS):
            text = "".join(node.text or "" for node in run.findall(".//w:t", NS))
            if not text:
                continue
            run_properties = run.find("w:rPr", NS)
            is_highlighted = False
            if run_properties is not None:
                highlight = run_properties.find("w:highlight", NS)
                is_highlighted = (
                    highlight is not None
                    and highlight.attrib.get("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}val") == "yellow"
                )
            runs.append((text, is_highlighted))
            full_text.append(text)

        paragraph_text = normalize_text("".join(full_text))
        if paragraph_text and paragraph_text not in DOCX_HEADER_LINES:
            paragraphs.append((paragraph_text, runs))

    return paragraphs


def parse_questions(paragraphs: list[tuple[str, list[tuple[str, bool]]]]) -> list[dict]:
    questions: list[dict] = []
    index = 0
    while index < len(paragraphs):
        prompt, _ = paragraphs[index]
        if looks_like_reference(prompt):
            index += 1
            continue

        options: list[tuple[str, list[tuple[str, bool]]]] = []
        cursor = index + 1
        while cursor < len(paragraphs):
            text, runs = paragraphs[cursor]
            if looks_like_reference(text) and len(options) in {2, 4}:
                highlighted_indexes = [
                    option_index
                    for option_index, (_, option_runs) in enumerate(options)
                    if any(flag for _, flag in option_runs)
                ]
                if len(highlighted_indexes) == 1:
                    questions.append(
                        {
                            "prompt": prompt,
                            "options": [option_text for option_text, _ in options],
                            "correct_index": highlighted_indexes[0],
                            "reference": text,
                        }
                    )
                index = cursor + 1
                break

            options.append((text, runs))
            cursor += 1
        else:
            index += 1

    return questions


def looks_like_reference(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Z]?\d+(?:-\d+)+(?:, *\d+(?:-\d+)*)*", value)) and len(value) <= 20 and "?" not in value


def question_format(options: list[str]) -> str:
    lowered = [option.lower() for option in options]
    if len(options) == 2 and lowered == ["true", "false"]:
        return "trueFalse"
    return "multipleChoice"


def category_id_for_reference(reference: str) -> str:
    prefix = reference_prefix(reference)
    if prefix.startswith("A") or prefix in {"5", "7"}:
        return "performance-limits-weather"
    if prefix in {"1", "2", "10", "40"}:
        return "systems-and-procedures"
    if prefix == "3":
        return "emergency-procedures"
    if prefix == "6":
        return "aerodynamics-and-handling"
    return "systems-and-procedures"


def reference_prefix(reference: str) -> str:
    first = reference.split(",")[0].strip()
    match = re.match(r"([A-Z]?\d+)-", first)
    return match.group(1) if match else "misc"


def build_tags(prompt: str, options: list[str], reference: str, category_id: str) -> list[str]:
    haystack = " ".join([prompt, *options, reference, category_id]).lower()
    tags = {"natops", category_id, f"ref-{reference.lower().replace(' ', '').replace(',', '-').replace('/', '-')}"}

    for tag, keywords in TOPIC_KEYWORDS.items():
        if any(keyword in haystack for keyword in keywords):
            tags.add(tag)

    return sorted(tags)


def normalize_text(value: str) -> str:
    value = value.replace("\u00a0", " ")
    value = re.sub(r"\s+", " ", value)
    return value.strip()


if __name__ == "__main__":
    raise SystemExit(main())
