#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path

from pypdf import PdfReader


LABEL_RE = re.compile(r"^([A-D])\.\s*(.*)$")
DASH_OPTION_RE = re.compile(r"^-\s*(.*)$")
PAGE_MARKER_RE = re.compile(r"\s*\d+\s*/\s*\d+\s*$")
TRUE_FALSE_PREFIX_RE = re.compile(r"^(?:True/\s*False|T/F):\s*", re.IGNORECASE)
TRUE_FALSE_ANSWER_RE = re.compile(r"\b(True|False)\s*$", re.IGNORECASE)


@dataclass
class ParsedQuestion:
    correct_letter: str
    prompt: str
    choices: list[tuple[str, str]]
    explanation: str | None = None


@dataclass
class RejectedBlock:
    line_number: int
    answer_line: str
    reason: str
    context: list[str]


def main() -> int:
    parser = argparse.ArgumentParser(description="Import a Quizlet-exported PDF into ground-school question-bank JSON.")
    parser.add_argument("source_pdf", type=Path)
    parser.add_argument("destination_json", type=Path)
    parser.add_argument("--event-code", default="CONTACTS-GS")
    parser.add_argument("--bank-id", default="contacts-gs-systems-1")
    parser.add_argument("--title", default="Systems 1")
    parser.add_argument(
        "--summary",
        default="Flight controls, hydraulics, landing gear, flaps, cockpit indications, avionics, and related T-6B systems questions.",
    )
    parser.add_argument(
        "--tag",
        action="append",
        dest="tags",
        help="Tag to apply to the bank and every imported question. May be repeated.",
    )
    parser.add_argument("--allow-rejected", action="store_true")
    parser.add_argument(
        "--layout",
        choices=["answer-first", "prompt-first"],
        default="answer-first",
        help="Quizlet PDF layout to parse. Systems sets use answer-first; Contact sets use prompt-first.",
    )
    parser.add_argument(
        "--strip-header",
        action="append",
        dest="strip_headers",
        help="Exact repeated page/header text to remove from extracted PDF lines. May be repeated.",
    )
    args = parser.parse_args()
    tags = args.tags or ["contacts", "groundSchool", "systems", "systems-1"]

    questions, rejected = parse_quizlet_pdf(args.source_pdf, layout=args.layout, strip_headers=args.strip_headers or [])
    if rejected and not args.allow_rejected:
        print_rejected(rejected)
        print(f"Rejected {len(rejected)} ambiguous blocks; rerun with --allow-rejected to write accepted questions.", file=sys.stderr)
        return 2

    destination = build_destination_bank(
        existing=load_existing(args.destination_json),
        event_code=args.event_code,
        bank_id=args.bank_id,
        title=args.title,
        summary=args.summary,
        tags=tags,
        questions=questions,
    )
    args.destination_json.parent.mkdir(parents=True, exist_ok=True)
    args.destination_json.write_text(json.dumps(destination, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print(f"Wrote {len(questions)} questions to {args.destination_json}")
    if rejected:
        print_rejected(rejected)
        print(f"Skipped {len(rejected)} ambiguous blocks.")
    return 0


def load_existing(destination: Path) -> dict:
    if not destination.exists():
        return {"questionBanks": []}
    return json.loads(destination.read_text(encoding="utf-8"))


def build_destination_bank(
    existing: dict,
    event_code: str,
    bank_id: str,
    title: str,
    summary: str,
    tags: list[str],
    questions: list[ParsedQuestion],
) -> dict:
    banks = [bank for bank in existing.get("questionBanks", []) if bank.get("id") != bank_id]
    banks.append(
        {
            "eventCode": event_code,
            "id": bank_id,
            "title": title,
            "summary": summary,
            "tags": tags,
            "questions": [
                {
                    "id": f"{bank_id}-{index:03d}",
                    "prompt": question.prompt,
                    "answer": choice_text(question.choices, question.correct_letter),
                    "format": question_format(question.choices),
                    "choices": [
                        {"id": letter.lower(), "text": text}
                        for letter, text in question.choices
                    ],
                    "correctChoiceID": question.correct_letter.lower(),
                    "explanation": question.explanation,
                    "tags": tags,
                }
                for index, question in enumerate(questions, start=1)
            ],
        }
    )
    return {"questionBanks": sorted(banks, key=lambda bank: bank["id"])}


def parse_quizlet_pdf(
    source: Path,
    layout: str = "answer-first",
    strip_headers: list[str] | None = None,
) -> tuple[list[ParsedQuestion], list[RejectedBlock]]:
    reader = PdfReader(str(source.expanduser()))
    text = "\n".join(page.extract_text() or "" for page in reader.pages)
    lines = content_lines(text, strip_headers=strip_headers or [])

    if layout == "prompt-first":
        return parse_prompt_first(lines)

    return parse_answer_first(lines)


def parse_answer_first(lines: list[str]) -> tuple[list[ParsedQuestion], list[RejectedBlock]]:
    questions: list[ParsedQuestion] = []
    rejected: list[RejectedBlock] = []
    index = 0
    while index < len(lines):
        match = LABEL_RE.match(lines[index])
        if not match:
            index += 1
            continue

        correct_letter = match.group(1)
        answer_text = match.group(2)
        option_start, choices, end_index = find_option_block(lines, start=index + 1, correct_letter=correct_letter)
        if option_start is None or choices is None or end_index is None:
            rejected.append(rejection(lines, index, "no valid answer choices found"))
            index += 1
            continue

        correct_option = dict(choices).get(correct_letter)
        if correct_option is None:
            rejected.append(rejection(lines, index, "correct choice label was not present in options"))
            index = end_index
            continue

        prompt, error = split_prompt(answer_text, lines[index + 1 : option_start], correct_option)
        if error is not None:
            rejected.append(rejection(lines, index, error))
            index = end_index
            continue

        questions.append(ParsedQuestion(correct_letter=correct_letter, prompt=prompt, choices=choices))
        index = end_index

    return questions, rejected


def parse_prompt_first(lines: list[str]) -> tuple[list[ParsedQuestion], list[RejectedBlock]]:
    questions: list[ParsedQuestion] = []
    rejected: list[RejectedBlock] = []
    index = 0

    while index < len(lines):
        if not is_prompt_first_card_start(lines, index):
            index += 1
            continue

        if TRUE_FALSE_PREFIX_RE.match(lines[index]):
            question, next_index, reason = parse_prompt_first_true_false(lines, index)
        else:
            question, next_index, reason = parse_prompt_first_multiple_choice(lines, index)

        if question is None:
            rejected.append(rejection(lines, index, reason or "ambiguous prompt-first question"))
            index = max(index + 1, next_index)
            continue

        questions.append(question)
        index = max(index + 1, next_index)

    return questions, rejected


def parse_prompt_first_true_false(
    lines: list[str],
    start: int,
) -> tuple[ParsedQuestion | None, int, str | None]:
    parts: list[str] = []
    for index in range(start, min(len(lines), start + 8)):
        if index > start and is_prompt_first_card_start(lines, index):
            break
        if DASH_OPTION_RE.match(lines[index]):
            break

        parts.append(lines[index])
        joined = clean_text(" ".join(parts))
        answer_match = TRUE_FALSE_ANSWER_RE.search(joined)
        if answer_match is None:
            continue

        prompt = clean_text(joined[: answer_match.start()])
        answer = answer_match.group(1).lower()
        if not prompt:
            return None, index + 1, "missing true/false prompt"

        correct_letter = "A" if answer == "true" else "B"
        return ParsedQuestion(
            correct_letter=correct_letter,
            prompt=prompt,
            choices=[("A", "True"), ("B", "False")],
        ), index + 1, None

    return None, start + 1, "true/false answer was not found"


def parse_prompt_first_multiple_choice(
    lines: list[str],
    start: int,
) -> tuple[ParsedQuestion | None, int, str | None]:
    index = start
    prompt_parts: list[str] = []
    while index < len(lines) and not DASH_OPTION_RE.match(lines[index]):
        prompt_parts.append(lines[index])
        index += 1
        if index - start > 12:
            return None, start + 1, "prompt did not reach an answer-choice block"

    prompt = clean_text(" ".join(prompt_parts))
    if not prompt:
        return None, start + 1, "missing prompt"

    choices: list[str] = []
    while len(choices) < 4:
        if index >= len(lines):
            return None, index, "incomplete answer-choice block"
        option_match = DASH_OPTION_RE.match(lines[index])
        if option_match is None:
            return None, index, f"expected {len(choices) + 1} answer choices"

        option_parts = [option_match.group(1)]
        index += 1
        if is_prompt_first_true_false_choices(choices + [clean_text(option_parts[0])]):
            choices.append(clean_text(option_parts[0]))
            break

        while index < len(lines) and not DASH_OPTION_RE.match(lines[index]):
            if len(choices) == 3:
                break
            if is_prompt_first_card_start(lines, index):
                return None, index, f"expected {len(choices) + 1} answer choices before next prompt"
            option_parts.append(lines[index])
            index += 1
        choices.append(clean_text(" ".join(option_parts)))
        if is_prompt_first_true_false_choices(choices):
            break

    match = best_prompt_first_answer_match(lines, answer_start=index, choices=choices)
    if match is None:
        return None, next_prompt_first_card_start(lines, index), "answer did not match any extracted choice"

    next_index, correct_letter, matched_choices = match
    return ParsedQuestion(
        correct_letter=correct_letter,
        prompt=prompt,
        choices=list(zip(["A", "B", "C", "D"][: len(matched_choices)], matched_choices)),
    ), next_index, None


def best_prompt_first_answer_match(
    lines: list[str],
    answer_start: int,
    choices: list[str],
) -> tuple[int, str, list[str]] | None:
    if len(choices) not in (2, 4):
        return None
    if answer_start >= len(lines) or is_definite_prompt_first_card_start(lines, answer_start):
        return None

    candidate_boundaries = prompt_first_boundary_candidates(lines, answer_start)
    best: tuple[float, int, str, list[str]] | None = None
    base_final_choice = choices[-1]

    for boundary in candidate_boundaries:
        tail = lines[answer_start:boundary]
        if not tail:
            continue

        for final_choice_extra_count in range(0, len(tail)):
            matched_choices = choices[:-1] + [
                clean_text(" ".join([base_final_choice] + tail[:final_choice_extra_count]))
            ]
            answer_text = clean_text(" ".join(tail[final_choice_extra_count:]))
            if not answer_text:
                continue

            letter_match = LABEL_RE.match(answer_text)
            if letter_match is not None:
                correct_letter = letter_match.group(1)
                choice_index = ord(correct_letter) - ord("A")
                if choice_index >= len(matched_choices):
                    continue
                label_answer = clean_text(letter_match.group(2))
                score = max(answer_similarity(label_answer, matched_choices[choice_index]), 0.98)
            else:
                scores = [answer_similarity(answer_text, choice) for choice in matched_choices]
                choice_index = max(range(len(scores)), key=scores.__getitem__)
                score = scores[choice_index]
                correct_letter = ["A", "B", "C", "D"][choice_index]

            if score < 0.84:
                continue

            if best is None or score > best[0] or (score == best[0] and boundary < best[1]):
                best = (score, boundary, correct_letter, matched_choices)

    if best is None:
        return None

    return best[1], best[2], best[3]


def prompt_first_boundary_candidates(lines: list[str], answer_start: int) -> list[int]:
    candidates: list[int] = []
    for index in range(answer_start + 1, min(len(lines), answer_start + 24)):
        if is_prompt_first_card_start(lines, index):
            candidates.append(index)
            break
    if not candidates:
        candidates.append(min(len(lines), answer_start + 24))
    return candidates


def next_prompt_first_card_start(lines: list[str], start: int) -> int:
    for index in range(start + 1, min(len(lines), start + 24)):
        if is_prompt_first_card_start(lines, index):
            return index
    return start


def is_prompt_first_card_start(lines: list[str], index: int) -> bool:
    if index >= len(lines) or DASH_OPTION_RE.match(lines[index]):
        return False
    if TRUE_FALSE_PREFIX_RE.match(lines[index]):
        return True

    for lookahead in range(index + 1, min(len(lines), index + 10)):
        if DASH_OPTION_RE.match(lines[lookahead]):
            return looks_like_contact_prompt(lines[index])
        if TRUE_FALSE_PREFIX_RE.match(lines[lookahead]):
            return False
    return False


def is_definite_prompt_first_card_start(lines: list[str], index: int) -> bool:
    if index >= len(lines):
        return False
    line = lines[index]
    if DASH_OPTION_RE.match(line):
        return False
    if TRUE_FALSE_PREFIX_RE.match(line):
        return True

    has_choices_ahead = any(
        DASH_OPTION_RE.match(lines[lookahead])
        for lookahead in range(index + 1, min(len(lines), index + 10))
    )
    if not has_choices_ahead:
        return False

    if "?" in line or "____" in line:
        return True
    return line.startswith(("How ", "If ", "Select ", "What ", "When ", "Where ", "Which "))


def is_prompt_first_true_false_choices(choices: list[str]) -> bool:
    return len(choices) == 2 and [normalized(choice) for choice in choices] in (["true", "false"], ["false", "true"])


def looks_like_contact_prompt(line: str) -> bool:
    if "?" in line or "____" in line:
        return True
    return line.startswith(
        (
            "A ",
            "An ",
            "All of the following",
            "Approach",
            "Aircraft",
            "Clearing",
            "Crosswind",
            "During ",
            "Either ",
            "For ",
            "Full ",
            "Gyroscopic",
            "How ",
            "If ",
            "In ",
            "Initial",
            "Intentional",
            "Landing",
            "Maneuver",
            "Most ",
            "Normal",
            "Power",
            "Recovery",
            "Select ",
            "Slow ",
            "Stalls",
            "Steady",
            "Takeoff",
            "The ",
            "To ",
            "Transferring",
            "Using ",
            "What ",
            "When ",
            "Where ",
            "Which ",
        )
    )


def content_lines(text: str, strip_headers: list[str] | None = None) -> list[str]:
    strip_headers = strip_headers or []
    lines: list[str] = []
    for raw_line in text.splitlines():
        line = clean_text(raw_line)
        if not line or line == "Sys1" or line.startswith("Study online"):
            continue
        if line in strip_headers:
            continue
        if re.fullmatch(r"\d+\s*/\s*\d+", line):
            continue
        lines.append(line)
    return lines


def find_option_block(
    lines: list[str],
    start: int,
    correct_letter: str,
) -> tuple[int | None, list[tuple[str, str]] | None, int | None]:
    for option_start in range(start, min(len(lines), start + 30)):
        if not lines[option_start].startswith("A. "):
            continue
        choices, end_index = parse_options(lines, option_start)
        if choices is not None and correct_letter in {letter for letter, _ in choices}:
            return option_start, choices, end_index
    return None, None, None


def parse_options(lines: list[str], start: int) -> tuple[list[tuple[str, str]] | None, int]:
    choices: list[tuple[str, str]] = []
    index = start
    expected = ["A", "B", "C", "D"]

    for expected_letter in expected:
        if index >= len(lines):
            return None, start
        match = LABEL_RE.match(lines[index])
        if match is None or match.group(1) != expected_letter:
            return None, start

        parts = [match.group(2)]
        index += 1
        while index < len(lines):
            next_match = LABEL_RE.match(lines[index])
            if next_match is not None and next_match.group(1) in expected:
                break
            if expected_letter == "D" and looks_like_prompt_before_options(lines, index):
                break
            parts.append(lines[index])
            index += 1

        choices.append((expected_letter, clean_text(" ".join(parts))))
        if is_true_false(choices):
            return choices, index

    return choices, index


def split_prompt(answer_text: str, between_answer_and_options: list[str], correct_option: str) -> tuple[str | None, str | None]:
    answer_parts = [answer_text]
    consumed = 0
    target = normalized(correct_option)

    while normalized(" ".join(answer_parts)) != target and consumed < len(between_answer_and_options):
        candidate = " ".join(answer_parts + [between_answer_and_options[consumed]])
        if target.startswith(normalized(candidate)):
            answer_parts.append(between_answer_and_options[consumed])
            consumed += 1
        else:
            break

    answer_joined = " ".join(answer_parts)
    if normalized(answer_joined) != target and not is_similar_answer(answer_joined, correct_option):
        return None, "answer header did not match the extracted correct choice"

    prompt = clean_text(" ".join(between_answer_and_options[consumed:]))
    if not prompt:
        return None, "missing prompt"
    return prompt, None


def looks_like_prompt_before_options(lines: list[str], index: int) -> bool:
    if index + 1 >= len(lines):
        return False
    return lines[index + 1].startswith("A. ") and (
        "?" in lines[index]
        or lines[index].startswith(("Which ", "What ", "When ", "Where ", "How ", "Why ", "To "))
        or "____" in lines[index]
    )


def clean_text(value: str) -> str:
    value = value.replace("\u00a0", " ")
    value = PAGE_MARKER_RE.sub("", value)
    value = re.sub(r"\bSys\d+\b", "", value)
    value = re.sub(r"\bT6-B\b", "T-6B", value)
    value = re.sub(r"(?<=\w)-\s+(?=\w)", "", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def normalized(value: str) -> str:
    value = clean_text(value).lower()
    value = value.replace("°", " degrees")
    value = re.sub(r"\bknots\b", " kias ", value)
    value = re.sub(r"\bthe\b", " ", value)
    value = re.sub(r"\bof\b", " ", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def answer_similarity(lhs: str, rhs: str) -> float:
    lhs_normalized = normalized(lhs)
    rhs_normalized = normalized(rhs)
    if not lhs_normalized or not rhs_normalized:
        return 0
    if lhs_normalized == rhs_normalized:
        return 1
    if lhs_normalized in rhs_normalized or rhs_normalized in lhs_normalized:
        return 0.94
    return SequenceMatcher(None, lhs_normalized, rhs_normalized).ratio()


def is_similar_answer(answer_header: str, correct_option: str) -> bool:
    lhs = normalized(answer_header)
    rhs = normalized(correct_option)
    length_ratio = len(lhs) / max(len(rhs), 1)
    return answer_similarity(answer_header, correct_option) >= 0.88 and length_ratio >= 0.52


def is_true_false(choices: list[tuple[str, str]]) -> bool:
    return len(choices) == 2 and [normalized(choice[1]) for choice in choices] in (["true", "false"], ["false", "true"])


def question_format(choices: list[tuple[str, str]]) -> str:
    return "trueFalse" if is_true_false(choices) else "multipleChoice"


def choice_text(choices: list[tuple[str, str]], letter: str) -> str:
    for choice_letter, text in choices:
        if choice_letter == letter:
            return text
    raise ValueError(f"Missing choice {letter}")


def rejection(lines: list[str], index: int, reason: str) -> RejectedBlock:
    return RejectedBlock(
        line_number=index + 1,
        answer_line=lines[index],
        reason=reason,
        context=lines[index : min(len(lines), index + 10)],
    )


def print_rejected(rejected: list[RejectedBlock]) -> None:
    for block in rejected:
        print(f"Rejected line {block.line_number}: {block.answer_line}", file=sys.stderr)
        print(f"  Reason: {block.reason}", file=sys.stderr)
        for line in block.context[1:]:
            print(f"    {line}", file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
