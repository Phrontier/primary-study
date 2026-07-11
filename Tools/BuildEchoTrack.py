#!/usr/bin/env python3
"""Build the compact Echo syllabus overlay from the canonical Echo reference.

The Delta manifest remains the shared content library. Echo events reuse authored
Delta sections and card IDs through the explicit event-source map below. Only
unmatched Echo discussion items produce new sections and cards.
"""

from __future__ import annotations

import copy
import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_CONTENT = ROOT / "Primary Gouge" / "AppContent"
ECHO_REFERENCE = APP_CONTENT / "Syllabi" / "EchoEventReference.json"
DELTA_REFERENCE = APP_CONTENT / "SyllabusEventReference.json"
DELTA_MANIFEST = APP_CONTENT / "StudyManifest.json"
DELTA_FLASHCARDS = APP_CONTENT / "FlashcardLibrary.json"
OVERRIDE_ROOT = APP_CONTENT / "EventContentOverrides"
OUTPUT = APP_CONTENT / "Syllabi" / "EchoTrack.json"
CROSSWALK_OUTPUT = APP_CONTENT / "Syllabi" / "EchoDeltaCrosswalk.json"
AUDIT_OUTPUT = APP_CONTENT / "Syllabi" / "EchoSyllabusAuditReport.json"


# Ordered candidates are an authoring decision, not a fuzzy global match. The
# first candidate supplies event-level metadata when the Echo event is not an
# exact same-code reuse. Additional candidates are section/card sources.
EVENT_SOURCES: dict[str, list[str]] = {
    "FAM1301": [],
    "FAM2103": ["FAM2201"],
    "FAM2104": ["FAM2202"],
    "FAM2105": ["FAM2201", "FAM3202"],
    "FAM3201": ["FAM3103"],
    "FAM3301": ["FAM3201"],
    "FAM3302": ["FAM3202"],
    "FAM3303": ["FAM3201", "FAM3202"],
    "FAM3401": ["FAM3301"],
    "FAM3501": ["FAM3401"],
    "FAM4601": ["FAM4701"],
    "FAM4602": ["FAM4702", "FAM4703", "FAM3401"],
    "FAM4790": ["FAM4701", "FAM4702", "FAM4703"],
    "FAM4801": ["FAM4490", "FAM4701"],
    "FAM4901": ["FAM4601"],
    "I6101": ["I2202", "I2201"],
    "I6102": ["I2201", "I2202"],
    "I6103": ["I2203"],
    "I6201": ["I6101", "I3101"],
    "I6202": ["I6102", "I4102"],
    "I3103": ["I6102", "I2202", "I2201", "FAM2202"],
    "I3104": ["I3103", "I2102"],
    "I3105": ["I3104", "I3206", "FAM4302"],
    "I3106": ["I3202", "I4304"],
    "I4104": ["I4103", "I3204", "I4302"],
    "I6301": ["I3201", "I3204", "I4202"],
    "N3102": ["N6101"],
    "N4102": ["N6101", "N4101"],
    "F1201": ["F2101", "F4101", "F4102", "F4103"],
}


TITLE_OVERRIDES = {
    "FAM1301": "Familiarization Flight Orientation",
    "FAM2103": "Takeoff and In-Flight Emergencies",
    "FAM2104": "Systems Emergencies",
    "FAM2105": "Smoke, Fire, Forced Landing, and Ejection",
    "FAM3201": "Crosswind Operations",
    "FAM3301": "PEL and ELP Fundamentals",
    "FAM3302": "Engine Failure, Forced Landing, and Ejection",
    "FAM3303": "Emergency Procedures Review",
    "FAM3401": "Advanced Crosswind and Windshear Operations",
    "FAM3501": "Introduction to Aerobatics",
    "FAM4601": "Aerobatics and OCF Recovery",
    "FAM4602": "Advanced Stalls and Spins",
    "FAM4790": "Aerobatics Check Flight",
    "FAM4801": "Aerobatic Solo",
    "FAM4901": "Night Familiarization",
    "I6101": "Arcing and Radial Intercepts",
    "I6102": "HSI Orientation and Point-to-Point",
    "I6103": "Holding Procedures",
    "I6201": "Procedure Turns and Missed Approach",
    "I6202": "Arcing, RVFAC, and Holding",
    "I3103": "RVFAC, ILS, and Point-to-Point",
    "I3104": "Radar Approaches and IMC Emergencies",
    "I3105": "Night Arcing and Circling",
    "I3106": "SID, STAR, and Departure Planning",
    "I4104": "Thunderstorms, Uncontrolled-Field Comms, and Stabilized Approaches",
    "I6301": "FMS, GPS, and HILO Procedures",
    "N3102": "Night Navigation",
    "N4102": "Night Visual Navigation Flight",
    "F1201": "Formation Flight Orientation",
    "F4101": "Formation Roles, Signals, and Abort Coordination",
    "F4102": "Blind, Lost-Sight, and Section Recovery",
    "F4103": "Section Emergencies and PEL",
    "F4104": "Cruise Maneuvering, Tail Chase, and Pursuit",
}


METADATA_OVERRIDES = {
    "FAM1301": (
        "Introduces the training system, event preparation, cockpit fit, grading standards, and the administrative habits required before the first flight.",
        "FAM1301 is the bridge from academics and simulators to aircraft training. It connects scheduling, flight gear, aircraft issue, weather, training records, CTS/MIF, and local policies with the physical cockpit setup and safety habits the student must demonstrate before flying."
    ),
    "FAM2103": (
        "Builds the immediate decision flow for aborts, runway departures, engine failures, airstarts, and uncommanded power or propeller events.",
        "FAM2103 concentrates the takeoff and airborne power-loss branches previously spread across Delta events. The study flow emphasizes aircraft control, rapid recognition, the correct airstart branch, forced-landing geometry, and the point where landing or ejection replaces troubleshooting."
    ),
    "FAM2105": (
        "Covers smoke and fire recognition, forced-landing priorities, and controlled versus immediate ejection decisions.",
        "FAM2105 closes the cockpit-emergency block with the events that demand the clearest stop-troubleshooting decision. Prepare the NATOPS actions and N/W/Cs together with smoke removal, landing-site judgment, and the conditions that distinguish controlled ejection from an immediate escape."
    ),
    "FAM3201": (
        "Develops crosswind planning and execution from computed limits through takeoff, pattern corrections, landing, abort, and runway-departure contingencies.",
        "FAM3201 is the Echo crosswind OFT. It combines wind calculations, control positioning, pattern geometry, on-speed AOA, HUD cross-checks, and continuous correction through touchdown while preserving the abort and prepared-surface emergency branches."
    ),
    "FAM3303": (
        "Provides a cumulative rehearsal of the FAM33 engine-failure, PEL, PEL/P, ELP, airstart, forced-landing, and ejection decision tree.",
        "FAM3303 is not a new procedure set; it is the block integration event. Use it to move cleanly from recognition to the correct profile and to explain why the aircraft state, altitude, landing option, and recovery progress change the choice between airstart, PEL, forced landing, and ejection."
    ),
    "FAM4601": (
        "Integrates unusual-attitude and OCF recovery with the complete aerobatic maneuver set and the T-6B V-N operating envelope.",
        "FAM4601 moves aerobatic knowledge into the aircraft. Preparation should connect each maneuver's energy plan and recovery cues to OCF prevention, unusual-attitude recovery, and the V-N diagram boundaries that keep the aircraft inside its authorized envelope."
    ),
    "FAM4602": (
        "Advances stall and spin recognition through inverted and progressive spins, accelerated stalls, AOA control, maneuvering speed, and acceleration limits.",
        "FAM4602 focuses on departure recognition and disciplined recovery as the aircraft state becomes less familiar. Tie spin progression, accelerated-stall cues, AOA, maneuvering speed, G limits, and the applicable emergency response into one coherent aircraft-control picture."
    ),
    "FAM4790": (
        "Checks safe, repeatable execution of previously introduced aerobatic maneuvers and the judgment that keeps the sequence inside aircraft and training limits.",
        "FAM4790 is the Echo aerobatics check flight. Review every introduced maneuver as a complete brief: entry setup, energy plan, execution, completion criteria, common errors, recovery, and the limit or cue that requires an early terminate or knock-it-off."
    ),
    "FAM4801": (
        "Prepares the aerobatic solo by reviewing authorized maneuvers, prohibited solo actions, OCF recovery, and day-of solo restrictions.",
        "FAM4801 shifts responsibility to the solo student. The standard is not merely maneuver recall: the student must know exactly what is authorized, protect the aircraft envelope, recognize a developing OCF state, recover without improvisation, and stop before a training error becomes unrecoverable."
    ),
    "I6101": (
        "Introduces arcing, station passage, and radial intercept geometry in the VTD.",
        "I6101 builds the orientation habits behind radio-instrument navigation. Use bearing, course, DME trend, turn direction, and intercept angle to maintain a continuous mental picture rather than waiting for the display to dictate each correction."
    ),
    "I6102": (
        "Develops HSI orientation and efficient VOR/DME point-to-point solutions.",
        "I6102 links HSI interpretation with point-to-point planning and continuous heading refinement. The goal is to predict bearing and course movement, select a useful initial solution, and update it smoothly without losing basic instrument control."
    ),
    "I6103": (
        "Builds holding-entry selection, no-wind orbit geometry, and wind-correction technique.",
        "I6103 turns holding from a diagram exercise into a repeatable cockpit procedure. Determine the entry, establish the protected pattern, correct outbound timing and headings from observed drift, and remain ahead of clearance and fuel requirements."
    ),
    "I6201": (
        "Combines clearance and departure procedures with procedure turns, teardrops, timing, VDP use, and missed-approach execution.",
        "I6201 rehearses the complete transition from clearance to approach completion. Maintain procedure awareness through departure and course reversal, compute timing deliberately, use the VDP correctly, and treat the missed approach as a planned maneuver rather than a surprise."
    ),
    "I6202": (
        "Integrates arcing, RVFAC, ILS/localizer procedures, holding, and shuttle descent in one VTD event.",
        "I6202 emphasizes procedure transitions and workload control. Build each approach before it begins, keep navigation orientation through arcs and vectors, manage holding or shuttle descent deliberately, and arrive at final configured with the missed approach already understood."
    ),
    "I3103": (
        "Combines RVFAC, ILS/localizer approaches, point-to-point navigation, and hydraulic-malfunction management.",
        "I3103 develops precise approach setup while continuing to manage navigation and aircraft-system contingencies. Keep the clearance, course, configuration, and final-approach picture ahead of the aircraft, then apply the hydraulic emergency branch without abandoning instrument control."
    ),
    "I3104": (
        "Develops PAR and ASR execution, backup-glideslope technique, IMC emergency priorities, and propeller-malfunction response.",
        "I3104 centers on radar approaches and degraded-aircraft decision making. Translate controller instructions into stable corrections, understand the no-glideslope picture, and preserve instrument control while handling the IMC and propeller emergencies assigned to the event."
    ),
    "I3105": (
        "Adds night cockpit setup, arcing and circling approaches, airport lighting, fuel planning, and fuel-system malfunctions.",
        "I3105 combines night instrument workload with two approaches that demand strong orientation. Prepare the cockpit and airport sketch, calculate fuel before launch, maintain protected maneuvering through the arc and circle, and recognize when a fuel-system problem changes the recovery plan."
    ),
    "I3106": (
        "Builds SID/STAR and obstacle-departure planning, Trouble T interpretation, and clearance pickup at uncontrolled airports.",
        "I3106 is a departure-and-arrival publication event. Read the procedure as a connected clearance, identify obstacle and takeoff restrictions before launch, distinguish assigned from expected constraints, and know how to obtain and verify an IFR clearance without tower support."
    ),
    "I4104": (
        "Integrates thunderstorm escape, uncontrolled-field communications, stabilized-approach criteria, descent-rate planning, and emergency review.",
        "I4104 tests whether the student can keep an instrument flight safe when weather, communications, energy, or aircraft condition degrades. Prepare the source-backed escape and communications procedures, calculate a usable descent rate, define the stabilized gate, and commit early to a missed approach when the picture is not acceptable."
    ),
    "I4103": (
        "Develops PAR, ASR, and no-gyro approaches while integrating hypoxia, hyperventilation, and OBOGS-malfunction recognition.",
        "I4103 combines radar-approach precision with degraded-instrument and physiological decision making. Translate controller calls into smooth corrections, maintain the no-gyro picture, and recognize when crew symptoms or OBOGS indications require immediate oxygen, communication, and recovery action."
    ),
    "I6301": (
        "Integrates FMS setup with GPS and HILO approach procedures in the VTD.",
        "I6301 focuses on using automation without surrendering procedure awareness. Build and verify the FMS route, understand GPS mode and waypoint behavior, and preserve the holding-pattern geometry, descent plan, and final-approach requirements of the HILO procedure."
    ),
    "N4102": (
        "Moves VNAV into a night aircraft event with chart interpretation, local SOP, HUD use, BASH, emergency-field selection, and night contingencies.",
        "N4102 requires the student to preserve route and terrain awareness when outside references are reduced. Use timing, lighting, HUD, and chart cues together; continuously reassess bird conditions and emergency fields; and keep the local night restrictions and engine-failure plan ahead of the aircraft."
    ),
    "F1201": (
        "Chair-flies the formation sortie from parade checkpoints and working-area communications through hand signals and emergency responsibilities.",
        "F1201 is the formation Flight 0 rehearsal. Practice the physical brief setup, outbound and return flow, parade sequence, visual and radio communications, and emergency coordination until both Lead and Wing responsibilities can be executed without losing formation discipline."
    ),
    "F4101": (
        "Establishes Lead/Wing responsibilities, hand-signal cadence, formation abort coordination, and area/sun management.",
        "F4101 sets the contracts that make the remainder of the formation block predictable. Both aircraft must understand who owns the decision, how visual signals and cadence are acknowledged, how an abort preserves runway separation, and how Lead manages geometry and sun so Wing can remain safe and effective."
    ),
    "F4102": (
        "Covers blind and lost-sight procedures, section speed-brake use, flight split, section approaches, and operations away from home field.",
        "F4102 focuses on maintaining separation and mission control when visual contact, geometry, or recovery conditions degrade. Prepare the immediate blind/lost-sight actions, coordinated configuration changes, flight-split responsibilities, and the communication and planning required for a section recovery away from home field."
    ),
    "F4103": (
        "Integrates section emergencies, section PEL, HEFOE, emergency-field selection, inadvertent IMC, gear inspection, and damaged-aircraft recovery.",
        "F4103 treats every emergency as both an aircraft problem and a formation problem. Lead and Wing must protect separation, assign tasks, select the safest recovery, and know when to dissolve the flight while supporting PEL, HEFOE, gear, IMC, or damaged-aircraft contingencies."
    ),
    "F4104": (
        "Develops terminate/KIO discipline, cruise maneuvering, tail chase, admin cruise, and lead-lag-pure pursuit geometry.",
        "F4104 is the advanced relative-motion event. Use pursuit geometry to control closure and position in cruise and Tail Chase, preserve step-down and energy, recognize unsafe trends early, and distinguish a normal terminate from the immediate safety response required by a knock-it-off."
    ),
    "F4290": (
        "Provides cumulative formation-maneuver and emergency-procedure preparation for the Echo formation check flight.",
        "F4290 verifies that formation knowledge transfers across the entire stage. Review each maneuver with Lead/Wing responsibilities, geometry, communications, limits, completion cues, and common errors, then apply the same disciplined crew coordination to any assigned emergency procedure."
    ),
}


# Explicit semantic equivalences where syllabus wording changed. Keys and values
# are normalized by normalized().
ITEM_ALIASES = {
    "firewarningonground": "fireonground",
    "emergencyengineshutdownontheground": "emergencyengineshutdownontheground",
    "aborttakeoff": "abortedtakeoff",
    "uncommandedpowerchangeslossofpower": "uncommandedpowerchangeslop",
    "uncommandedpropfeather": "uncommandedpropfeather",
    "precautionaryemergencylandingpelandbfi": "precautionaryemergencylandingpelandbfi",
    "crosswindtakeofftouchandgofullstoplandings": "crosswindtakeoffandlandings",
    "aircraftdepartsapreparedsurface": "aircraftdepartspreparedsurface",
    "anypreviouslydiscusseditems": "anypreviouslydiscusseditems",
    "anypreviouslyintroducedmaneuver": "anypreviouslydiscussedmaneuverorprocedure",
    "all aerobatic maneuvers": "aerobaticmaneuvers",
    "nightvisualnavigationprocedures": "nightvnavigationtimingandcoursecorrections",
    "localnightsops": "localnightvnavigationsop",
    "anyapplicablenightemergency": "anyapplicablenightemergencyprocedure",
    "formationvoicecommunications": "formationcommunications",
    "formationemergencyprocedures": "sectionemergencies",
    "designatedflightleadformationleadwingresponsibilities": "wingmanflightleaderresponsibilities",
    "sectionemergencies": "sectionpelprocedures",
    "knockitoff": "knockitoffterminateprocedures",
    "terminate": "knockitoffterminateprocedures",
    "cruisemaneuvering": "cruisepositionmaneuvering",
    "admincruiseandcruiseposition": "admincruise",
    "hsiorientationandpointtopoint": "hsiorientation",
    "overthestationpassage": "stationpassage",
    "missedapproachprocedures": "missedapproach",
    "parwogs": "par",
    "ptp": "pointtopoint",
    "airportsketchlightingsystems": "nightcockpitsetup",
    "sidstar": "sidstar",
    "obstacledepartureprocedure": "obstacledepartureprocedures",
    "uncontrolledfieldinstrumentcomms": "highaltitudeapproachandnonradarenvironmentcommunications",
    "fmsprocedures": "fmsflightplanusagesidstarholdingandapproachandfmsarrivals",
    "gpsapproachprocedures": "gpsapproaches",
    "hiloapproachprocedures": "hiloapproaches",
}


ITEM_SOURCE_OVERRIDES = {
    ("FAM2105", "immediate ejection"): ("FAM3202", "eject"),
    ("FAM6102", "“IMSAFE” checklists and its incorporation into overall ORM"): ("FAM6102", "“IMSAFE” checklist"),
    ("FAM4601", "T-6B VN diagram"): ("FAM4703", "T-6B VN diagram"),
    ("FAM4790", "Any previously introduced maneuver"): ("F4290", "Any previously discussed maneuver"),
    ("FAM4801", "OCF recovery"): ("FAM4701", "OCF recovery procedures"),
    ("I3103", "ILS/LOC approaches"): ("I4102", "ILS/LOC approach procedures"),
    ("I3105", "arcing approach"): ("I3101", "arcing approaches"),
    ("I3105", "circling approach"): ("I4302", "circling maneuver"),
    ("I3105", "fuel planning"): ("I4301", "Flight planning"),
    ("I3105", "fuel system malfunctions"): ("FAM4302", "Fuel system"),
    ("I4104", "any emergency procedure"): ("I4304", "any emergency procedure"),
    ("I4103", "no-gyro approaches"): ("I3203", "No-gyro approach and BFI approach"),
    ("I4103", "hypoxia/hyperventilation"): ("I2202", "hyperventilation/hypoxia"),
    ("I4103", "OBOGS malfunctions"): ("I2202", "OBOGS malfunctions"),
    ("I6301", "HILO approach procedures"): ("I6101", "HILO approach procedure"),
    ("N4102", "Night visual navigation procedures"): ("N6101", "Night VNAV timing and course corrections"),
    ("N4102", "HUD"): ("N3101", "HUD"),
    ("F1201", "local SOP working area and communications"): ("F2101", "formation communications"),
    ("F1201", "formation emergency procedures"): ("F4103", "Section PEL"),
    ("F4101", "hand signals and cadence"): ("F4101", "Hand signals"),
    ("F4101", "area/sun management"): ("F4102", "area/sun management"),
    ("F4102", "Blind procedures"): ("F4101", "blind procedures"),
    ("F4102", "lost sight procedures"): ("F4101", "lost sight procedures"),
    ("F4102", "flight split"): ("CS2102", "dissolving the flight (flight split)"),
    ("F4102", "section approach"): ("CS2101", "section approach procedures"),
    ("F4102", "other-than-homefield operations"): ("I4301", "Strange Field operations"),
    ("F4103", "HEFOE"): ("F4101", "HEFOE"),
    ("F4103", "landing gear inspection"): ("F4104", "Landing gear inspection"),
    ("F4103", "airborne damaged aircraft"): ("F4102", "Airborne damaged aircraft"),
    ("F4104", "admin cruise and cruise position"): ("CS2101", "Cruise position/maneuvering"),
    ("F4104", "principles of pursuit geometry"): ("F4104", "principles of lead"),
}


def load(path: Path):
    return json.loads(path.read_text())


def rewrite_event_codes(value, source_codes: list[str], target_code: str):
    replacements = [code for code in source_codes if code != target_code]
    if isinstance(value, str):
        for source_code in replacements:
            value = value.replace(source_code, target_code)
        return value
    if isinstance(value, list):
        return [rewrite_event_codes(item, source_codes, target_code) for item in value]
    if isinstance(value, dict):
        return {key: rewrite_event_codes(item, source_codes, target_code) for key, item in value.items()}
    return value


def normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def title_case(value: str) -> str:
    acronyms = {
        "aoa": "AOA", "bfi": "BFI", "bash": "BASH", "cfs": "CFS",
        "cnaf": "CNAF", "crm": "CRM", "elp": "ELP", "fih": "FIH",
        "fms": "FMS", "gca": "GCA", "gps": "GPS", "hefoe": "HEFOE",
        "hilo": "HILO", "hsi": "HSI", "hud": "HUD", "ils": "ILS",
        "imc": "IMC", "loc": "LOC", "nwc": "NWC", "obogs": "OBOGS",
        "ocf": "OCF", "olf": "OLF", "orm": "ORM", "par": "PAR",
        "pel": "PEL", "pmu": "PMU", "rdo": "RDO", "rvfac": "RVFAC",
        "sid": "SID", "sop": "SOP", "star": "STAR", "tac": "TAC",
        "tot": "TOT", "ufcp": "UFCP", "vdp": "VDP", "vfr": "VFR",
        "vor": "VOR",
    }
    words = re.split(r"(\s+|/|-)", value.strip())
    result = []
    for index, word in enumerate(words):
        key = word.lower()
        if key in acronyms:
            result.append(acronyms[key])
        elif not word or word.isspace() or word in {"/", "-"}:
            result.append(word)
        elif index > 0 and key in {"and", "or", "of", "to", "in", "for", "the"}:
            result.append(key)
        else:
            result.append(word[:1].upper() + word[1:])
    return "".join(result)


def tokens(value: str) -> set[str]:
    ignored = {"and", "or", "the", "a", "an", "any", "procedures", "procedure"}
    return {x for x in re.findall(r"[a-z0-9]+", value.lower()) if x not in ignored}


def item_similarity(lhs: str, rhs: str) -> float:
    left, right = tokens(lhs), tokens(rhs)
    jaccard = len(left & right) / len(left | right) if left | right else 0
    return max(jaccard, SequenceMatcher(None, normalized(lhs), normalized(rhs)).ratio())


def generic_section(item: str, event: dict) -> dict:
    display = title_case(item)
    lower = item.lower()
    if "any previously" in lower or "any item discussed" in lower:
        items = [
            {"text": "Use the event as a cumulative review: identify the maneuver or procedure, state its setup and governing limits, then brief execution, completion cues, and the applicable safety boundaries."},
            {"text": "Prioritize weak or high-consequence items rather than repeating only the most familiar material."},
            {"text": "Resolve disagreements with the current FTI, NATOPS, checklist, and local guidance before the brief."},
        ]
    elif any(term in lower for term in ["emergency", "failure", "malfunction", "eject", "fire", "smoke"]):
        items = [
            {"text": f"Brief {display} from recognition through the required response, using the current NATOPS/checklist wording for all critical actions."},
            {"text": "State the aircraft-control priority, the cues that change the response, and the point at which continued troubleshooting is no longer appropriate."},
            {"text": "Include the applicable warnings, cautions, notes, landing decision, and ejection boundary without inventing local or unsupported criteria."},
        ]
    elif any(term in lower for term in ["landing", "takeoff", "maneuver", "approach", "spin", "stall", "roll", "loop"]):
        items = [
            {"text": f"Brief {display} in the same order it is flown: setup, entry conditions, control sequence, visual/instrument references, and completion criteria."},
            {"text": "Use the controlling FTI for speeds, power, altitude, configuration, and recovery parameters; verify local restrictions during the event brief."},
            {"text": "Identify the common errors and the safety cue that requires an early correction, terminate call, wave-off, or recovery."},
        ]
    elif any(term in lower for term in ["planning", "chart", "weather", "notam", "minimum", "fuel", "route"]):
        items = [
            {"text": f"Treat {display} as an operational planning product: identify the governing source, build the required product, cross-check it, and explain how it affects the go/no-go or continuation decision."},
            {"text": "Use current publications and day-of information for weather, NOTAMs, fuel, airfield, route, and local requirements."},
            {"text": "Brief the error traps that would make the plan unusable or unsafe, then identify the backup when assumptions change."},
        ]
    else:
        items = [
            {"text": f"Explain the purpose of {display}, where it appears in the event flow, and what correct application should accomplish."},
            {"text": "Tie the discussion to the current FTI and local brief rather than memorizing an isolated definition."},
            {"text": "Identify the cue, decision, or cross-check that makes the knowledge operationally useful in the aircraft or simulator."},
        ]
    return {"title": display, "items": items}


FAM1301_CONTENT = {
    "scheduling": [
        "Know where the official schedule is published, the required show time, and the chain used to resolve a conflict or last-minute change.",
        "Plan backward from brief time for publications, weather, flight gear, aircraft assignment, and mission products; never let an unofficial schedule source become the only source checked.",
    ],
    "snivels": [
        "A snivel is a request for relief from scheduled training because the student is not medically or otherwise ready to train.",
        "Use the current squadron procedure promptly and honestly; hiding a condition or waiting until brief time creates avoidable training and safety risk.",
    ],
    "brief and debrief": [
        "Arrive ready to lead the assigned portions of the brief with current publications, weather, mission products, and questions already identified.",
        "During debrief, capture cause-and-effect feedback and the corrective action for the next event; the syllabus requires detailed, comprehensive feedback tied to CTS performance.",
    ],
    "flight gear check": [
        "Bring all required flight gear, inspect it for condition and configuration, and resolve missing or unserviceable equipment before the event.",
        "FAM1301 also requires the student, wearing the survival vest, to locate, identify, and discuss the function of each ALSS item.",
    ],
    "seat height": [
        "Set seat height before final strap-in so the outside sight picture, HUD, controls, and ejection-seat geometry are correct.",
        "Recheck reach and visibility after restraint adjustment; do not accept a position that requires stretching or blocks full control movement.",
    ],
    "rudder pedal adjustment": [
        "Adjust the pedals for full rudder and brake travel while maintaining a secure, repeatable seated position.",
        "Verify both legs can apply symmetrical control without locking the knees or compromising restraint fit.",
    ],
    "feet positioning on rudder and brake pedals": [
        "Use deliberate foot placement so rudder inputs do not unintentionally apply brakes and brake application does not reduce directional control.",
        "Reposition consciously between taxi/braking tasks and flight-control tasks rather than riding the brakes.",
    ],
    "aircraft issue": [
        "Confirm the assigned aircraft, status, fuel, publications, and known discrepancies through the current squadron issue process.",
        "Do not treat assignment as acceptance: the aircrew still verifies suitability during records review, exterior inspection, and cockpit checks.",
    ],
    "weight and balance": [
        "Verify the aircraft loading is within authorized weight and center-of-gravity limits for the planned event.",
        "Account for crew, equipment, fuel, and configuration changes; carry the result into performance planning rather than treating it as isolated paperwork.",
    ],
    "aircraft discrepancy reporting": [
        "Report discrepancies clearly with the indication, conditions, crew action, and whether the condition repeated or cleared.",
        "Use the approved maintenance and squadron process; never normalize an unexplained indication or conceal it from the next crew.",
    ],
    "ATF": [
        "The Aviation Training Form records the event, maneuver grades, comments, and training outcome.",
        "Review it for accuracy and connect comments to the causal error and corrective action; an UNSAT is identified with a pink ATF.",
    ],
    "ATS": [
        "The Aviation Training Summary is the stage-level table of MIF requirements and maneuver grades.",
        "Use it to understand progression and identify items that must reach the block standard, not as a substitute for reading the event MIF and CTS.",
    ],
    "CTS": [
        "Course Training Standards define the required behavior and performance standard for each graded item in Chapter IX.",
        "Being numerically inside a tolerance does not excuse delayed, erratic, unsafe, or inappropriate control; corrections must be timely and aircraft control smooth and positive.",
    ],
    "MIF": [
        "The Maneuver Item File lists the required maneuvers and minimum proficiency level for each training block.",
        "By the end of block, every critical and attempted optional item must meet the required standard; use the event table to see what is introduced, practiced, or required.",
    ],
    "headwork": [
        "Headwork combines situational awareness, flexibility, capacity, flight discipline, and sound decisions as conditions change.",
        "The practical standard is to recognize mission impacts early, select the safest effective action, and reduce workload before saturation compromises the aircraft or mission.",
    ],
    "basic air work": [
        "Basic Air Work is the baseline aircraft-control standard: maintain altitude within 100 feet, airspeed within 10 KIAS, and heading within 10 degrees unless a maneuver specifies otherwise.",
        "Use coordinated power, attitude, and trim with smooth, positive control and level off within 100 feet.",
    ],
    "emergency procedures": [
        "Maintain in-depth NATOPS and directive knowledge, recognize the situation, and perform critical actions from memory with complete accuracy.",
        "Use the checklist when conditions permit, complete the procedure promptly, and keep aircraft control and the landing/ejection decision ahead of troubleshooting.",
    ],
    "exams": [
        "Treat exams as confirmation that the underlying systems, procedures, and publications can be applied, not as isolated question memorization.",
        "Resolve missed concepts in the controlling source before the associated simulator or flight block.",
    ],
    "FTI reference material": [
        "The Flight Training Instruction is the CNATRA-approved description of flight procedures and techniques for the stage.",
        "Use the current FTI for maneuver setup, execution, recovery, and technique, while NATOPS remains controlling for aircraft limitations and emergency procedures.",
    ],
    "FWB website usage and obtaining weather brief": [
        "Use the approved Flight Weather Brief service and current squadron process to obtain the weather product required for the mission.",
        "Check validity, hazards, route, destination, alternate, winds, and updates; obtain a rebrief or extension when the briefing is no longer valid.",
    ],
    "TMS": [
        "The Training Management System is the official system used to manage training events and records.",
        "Verify assignments and completed-event information through the current workflow and promptly correct discrepancies through the appropriate chain.",
    ],
    "tower visit (if able)": [
        "Use the tower visit to understand controller responsibilities, traffic sequencing, runway environment, and how pilot calls affect the controller's picture.",
        "Connect what is observed to concise radio calls, readbacks, situational awareness, and local course-rule compliance.",
    ],
    "DOR/TTO policy": [
        "DOR means Drop on Request; TTO means Training Time Out. Know the current command policy, purpose, and notification path for each.",
        "A safety or training concern should be raised immediately and without fear of delaying the event; local policy supplies the administrative steps.",
    ],
    "PCL cutoff and inadvertent engine shutdown": [
        "Protect the PCL from inadvertent movement through the cutoff gate and maintain deliberate hand placement during ground operations and critical transitions.",
        "If shutdown occurs, preserve directional control and execute the applicable NATOPS response rather than rushing an unsupported restart.",
    ],
    "fuel cutoff gate finger lift guard": [
        "The finger-lift gate is a deliberate barrier against unintended movement into fuel cutoff.",
        "Manipulate it only as required by the checklist or emergency procedure and positively verify the intended PCL position.",
    ],
}


def special_sections(event_code: str, item: str) -> list[dict] | None:
    if event_code == "FAM1301" and item in FAM1301_CONTENT:
        return [{"title": title_case(item), "items": [{"text": text} for text in FAM1301_CONTENT[item]]}]
    special_content = {
        ("FAM2102", "No start"): [
            "Recognize a no start when ITT does not rise within 10 seconds after fuel-flow indications.",
            "Abort the start using the applicable checklist action; if fuel was introduced, complete the required motoring run and report the discrepancy.",
        ],
        ("FAM2102", "hung start"): [
            "A hung start is indicated when N1 stops increasing normally during the start sequence.",
            "Abort before the start progresses outside limits, then complete the motoring run when fuel was introduced and document the malfunction.",
        ],
        ("FAM2102", "hot start"): [
            "Recognize a hot start from an abnormally rapid ITT rise or a trend likely to exceed the start limit.",
            "Do not wait for an automatic abort when the trend requires manual action; secure the start, motor as required, and report any overtemperature.",
        ],
        ("FAM2102", "loss of start ready light during start sequence"): [
            "Loss of ST READY means automatic start protection is no longer available. ST READY must be stable before AUTO/RESET is selected and remain illuminated through the protected start sequence.",
            "If it extinguishes during start, manually abort using the checklist branch appropriate to PCL position, then motor the engine if fuel was introduced.",
        ],
        ("FAM2102", "battery bus light during start"): [
            "A red BATT BUS warning during start is an immediate abort condition because display failure and loss of start monitoring may follow.",
            "Abort promptly, preserve the ability to monitor the engine, and complete the applicable abort-start and motoring-run actions.",
        ],
        ("FAM3201", "on-speed crosscheck incorporation in crosswind conditions"): [
            "Use on-speed AOA as the primary energy cross-check while preserving the required crosswind correction and ground track through the approach turn and final.",
            "Do not trade AOA control for runway alignment: correct drift with coordinated flight-path changes, keep bank within pattern limits, and wave off when a stable correction cannot be maintained.",
        ],
        ("FAM4801", "Any previously introduced maneuver"): [
            "Review each authorized solo maneuver as a complete flow: setup, entry conditions, energy plan, execution, completion cues, recovery, and the limit that requires an early stop.",
            "Use the current FTI and day-of solo brief; familiarity from a dual event does not by itself authorize solo execution.",
        ],
        ("FAM4801", "Prohibited SNA solo maneuvers"): [
            "Brief the current syllabus, NATOPS, FTI, and local solo restrictions before accepting the aircraft; if a maneuver is not expressly authorized for solo execution, do not perform it.",
            "Use the ODO/FDO solo brief and day-of restrictions as the final go/no-go boundary.",
        ],
        ("FAM4801", "OCF recovery"): [
            "Recognize departure early, neutralize aggravating controls, and execute the current FTI/NATOPS OCF recovery without improvising a solo test point.",
            "If recovery is not prompt or the aircraft state becomes unrecoverable, transition immediately to the applicable ejection decision.",
        ],
        ("FAM3303", "Any item discussed in block"): [
            "Prepare the complete FAM33 decision chain: recognize engine-failure indications, select PEL/PEL-P/ELP geometry, execute the appropriate airstart or forced-landing branch, and state the ejection boundary.",
            "Use the current NATOPS, EP/N/W/C references, and Contact FTI; review weak branches rather than rehearsing only the preferred outcome.",
        ],
        ("I4104", "stabilized approach criteria (FAA Instrument Procedures Handbook)"): [
            "A stabilized approach has the aircraft on the correct lateral and vertical path, in the intended configuration, at the planned airspeed and descent rate, with only small corrections required.",
            "Brief the gate and limits from the current FAA Instrument Procedures Handbook, FTI, and local guidance; if the approach is not stable by the required point, execute the missed approach or wave-off.",
        ],
        ("I4104", "rate of descent calculation"): [
            "Convert the published descent gradient and actual groundspeed into a target vertical speed before beginning descent; for a nominal 3-degree path, groundspeed multiplied by about five gives a useful feet-per-minute cross-check.",
            "Recompute when groundspeed changes, compare the result with altitude-to-go and distance-to-go, and correct early rather than chasing the glidepath close to minimums.",
        ],
        ("N4102", "BASH"): [
            "Review current Bird/Animal Strike Hazard conditions for departure, route, destination, and recovery, then incorporate the risk into altitude, timing, routing, and go/no-go decisions.",
            "Update the assessment when conditions change and follow current local reporting, avoidance, and restriction procedures rather than relying on a preflight snapshot.",
        ],
        ("F1201", "Parade sequence checkpoints"): [
            "Chair-fly the parade sequence in order and verbalize the checkpoint that confirms each position before moving to the next maneuver.",
            "Wing should control wingtip separation, step-down, and bearing with small coordinated corrections while Lead remains predictable and monitors Wing's ability to continue.",
        ],
        ("F4103", "Section emergencies"): [
            "Treat a section emergency as both an aircraft problem and a formation-separation problem: fly the affected aircraft, communicate the malfunction, and establish clear Lead/Wing responsibilities.",
            "Lead remains directive, protects the emergency aircraft, coordinates recovery, and dissolves or reconfigures the flight when formation adds risk; Wing maintains safe position and avoids compounding the emergency.",
        ],
        ("F4104", "tail chase"): [
            "Tail Chase demonstrates lead, lag, and pure pursuit in dynamic maneuvering. Wing normally maintains 800-1000 feet in trail, offset from prop wash, and uses pursuit geometry instead of chasing position with power.",
            "Do not conduct Tail Chase below 6000 feet AGL or within 500 feet of the bottom of the assigned block, whichever is higher; avoid less than 1 G, more than 6 G, or slower than 110 KIAS.",
            "Split-S and Immelmann maneuvers are prohibited. Call knock-it-off for a safety deviation, then make Lead predictable and recover the formation deliberately.",
        ],
    }
    if (event_code, item) in special_content:
        return [{"title": title_case(item), "items": [{"text": text} for text in special_content[(event_code, item)]]}]
    return None


def section_from_authored_card(item: str, card: dict) -> dict:
    lines = [line.strip() for line in card.get("answer", "").splitlines() if line.strip()]
    entries = []
    for line in lines:
        entries.append({"text": line[2:].strip() if line.startswith("- ") else line})
    return {"title": title_case(item), "items": entries[:8]}


def generic_card(event_code: str, item: str, sections: list[dict], event_kind: str) -> dict:
    if len(sections) > 1:
        bullets = [section["items"][0]["text"] for section in sections if section.get("items")][:3]
    else:
        bullets = [entry["text"] for entry in sections[0]["items"][:3]]
    answer = "\n".join(f"- {bullet}" for bullet in bullets)
    return {
        "id": f"echo-{event_code.lower()}-{re.sub(r'[^a-z0-9]+', '-', item.lower()).strip('-')}",
        "prompt": f"How should you brief {title_case(item)} for {event_code}?",
        "answer": answer,
        "imageRelativePath": None,
        "tags": ["procedures"],
        "studyCategories": [{"groundSchool": "groundSchool", "sim": "sims", "flight": "flights"}[event_kind]],
        "eventCodes": [event_code],
        "kind": "standard",
        "requiresVerbatim": False,
        "companionGroupID": None,
    }


def main() -> None:
    echo_reference = load(ECHO_REFERENCE)
    delta_reference = load(DELTA_REFERENCE)
    manifest = load(DELTA_MANIFEST)
    authored_cards_file = load(DELTA_FLASHCARDS)

    delta_ref_by_code = {event["code"]: event for event in delta_reference["events"]}
    delta_events = {
        event["code"]: event
        for phase in manifest["phases"]
        for category in phase["categories"]
        for event in category["events"]
    }
    manifest_cards = {card["id"]: card for card in manifest["flashcards"]}
    authored_cards = {card["id"]: card for card in authored_cards_file["flashcards"]}

    overrides = {}
    for path in OVERRIDE_ROOT.glob("*.json"):
        if path.name == "FAMDiscussionAuthoringConfig.json":
            continue
        try:
            value = load(path)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict) and value.get("code"):
            overrides[value["code"]] = value

    sections_by_source: dict[str, dict[str, list[dict]]] = defaultdict(dict)
    section_owners: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    for code, override in overrides.items():
        notes = override.get("studyNotes") or {}
        sections = {section.get("title"): section for section in notes.get("sections", [])}
        for canonical_item, titles in (override.get("canonicalCoverage") or {}).items():
            sections_by_source[code][normalized(canonical_item)] = [
                copy.deepcopy(sections[title]) for title in titles if title in sections and title != "Required Procedures"
            ]
            for title in titles:
                if title != "Required Procedures":
                    section_owners[code][title].add(normalized(canonical_item))

    authored_coverage: dict[tuple[str, str], list[str]] = defaultdict(list)
    for card in authored_cards.values():
        for coverage in card.get("eventCoverage", []):
            for item in coverage.get("discussionItems", []):
                authored_coverage[(coverage["eventCode"], normalized(item))].append(card["id"])

    # The overlay contains canonical Echo events only. The repository merges the
    # existing shared academic containers into Ground School at load time.
    base_phase_by_id = {phase["id"]: phase for phase in manifest["phases"]}
    phase_ids = ["contacts", "instruments", "vnav", "formation"]
    phases = []
    for phase_id in phase_ids:
        phase = copy.deepcopy(base_phase_by_id[phase_id])
        for category in phase["categories"]:
            category["events"] = []
        phases.append(phase)

    phase_by_category = {
        "familiarization": "contacts",
        "instruments": "instruments",
        "navigation": "vnav",
        "formation": "formation",
    }
    category_kind_by_event_kind = {
        "groundSchool": "groundSchool", "sim": "sims", "flight": "flights"
    }

    extra_cards: dict[str, dict] = {}
    crosswalk_events = []
    item_issues = []

    for reference_event in echo_reference["events"]:
        code = reference_event["code"]
        source_codes = EVENT_SOURCES.get(code, [code] if code in delta_events else [])
        primary_source = source_codes[0] if source_codes else None
        source_event = copy.deepcopy(delta_events.get(primary_source, {}))
        full_exact_reuse = (
            primary_source is not None
            and primary_source in delta_ref_by_code
            and [normalized(x) for x in reference_event["discussionItems"]]
            == [normalized(x) for x in delta_ref_by_code[primary_source]["discussionItems"]]
        )

        item_mappings = []
        visible_sections = []
        seen_section_titles = set()
        event_card_ids: list[str] = []

        candidate_items = []
        for source_code in source_codes:
            for source_item in delta_ref_by_code.get(source_code, {}).get("discussionItems", []):
                candidate_items.append((source_code, source_item))

        for echo_item in reference_event["discussionItems"]:
            echo_norm = normalized(echo_item)
            alias_norm = normalized(ITEM_ALIASES.get(echo_norm, ITEM_ALIASES.get(echo_item.lower(), echo_norm)))
            match = None

            explicit_source = ITEM_SOURCE_OVERRIDES.get((code, echo_item))
            if explicit_source:
                match = (explicit_source[0], explicit_source[1], "explicit")

            if match is None:
                for source_code, source_item in candidate_items:
                    if normalized(source_item) in {echo_norm, alias_norm}:
                        match = (source_code, source_item, "exact" if normalized(source_item) == echo_norm else "alias")
                        break

            if match is None and candidate_items:
                ranked = sorted(
                    ((item_similarity(echo_item, source_item), source_code, source_item)
                     for source_code, source_item in candidate_items),
                    reverse=True,
                )
                if ranked and ranked[0][0] >= 0.72:
                    score, source_code, source_item = ranked[0]
                    match = (source_code, source_item, f"reviewed-candidate:{score:.2f}")

            mapped_sections = []
            mapped_card_ids = []
            if match:
                source_code, source_item, method = match
                mapped_sections = copy.deepcopy(
                    sections_by_source.get(source_code, {}).get(normalized(source_item), [])
                )
                if any(len(section_owners[source_code].get(section.get("title"), set())) > 1 for section in mapped_sections):
                    mapped_sections = []
                    method += "+split-presentation"
                mapped_card_ids.extend(authored_coverage.get((source_code, normalized(source_item)), []))

                # For complete event reuse, preserve every validated deck card. For
                # partial reuse, add reference cards only when their prompt materially
                # matches the mapped canonical item.
                source_deck_ids = [
                    card_id
                    for deck in delta_events[source_code].get("flashcardDecks", [])
                    for card_id in deck.get("cardIDs", [])
                ]
                if full_exact_reuse and source_code == primary_source:
                    mapped_card_ids.extend(source_deck_ids)
                else:
                    for card_id in source_deck_ids:
                        if card_id in authored_cards:
                            continue
                        prompt = manifest_cards.get(card_id, {}).get("prompt", "")
                        if item_similarity(source_item, prompt) >= 0.36:
                            mapped_card_ids.append(card_id)
            else:
                source_code = None
                source_item = None
                method = "new"

            if not mapped_sections:
                mapped_sections = special_sections(code, echo_item) or []
                if not mapped_sections:
                    authored_match = next(
                        (authored_cards[card_id] for card_id in mapped_card_ids if card_id in authored_cards),
                        None,
                    )
                    if authored_match:
                        mapped_sections = [section_from_authored_card(echo_item, authored_match)]
                if not mapped_sections:
                    mapped_sections = [generic_section(echo_item, reference_event)]
                if match:
                    method += "+new-presentation"

            for section in mapped_sections:
                title = section.get("title") or title_case(echo_item)
                if title not in seen_section_titles:
                    visible_sections.append(section)
                    seen_section_titles.add(title)

            mapped_card_ids = list(dict.fromkeys(mapped_card_ids))
            if not mapped_card_ids:
                new_card = generic_card(code, echo_item, mapped_sections, reference_event["eventKind"])
                # Keep IDs unique when two items normalize to the same slug.
                candidate_id = new_card["id"]
                suffix = 2
                while candidate_id in extra_cards:
                    candidate_id = f"{new_card['id']}-{suffix}"
                    suffix += 1
                new_card["id"] = candidate_id
                extra_cards[candidate_id] = new_card
                mapped_card_ids = [candidate_id]

            event_card_ids.extend(mapped_card_ids)
            item_mappings.append({
                "discussionItem": echo_item,
                "sourceEventCode": source_code,
                "sourceDiscussionItem": source_item,
                "method": method,
                "sectionTitles": [section.get("title") for section in mapped_sections],
                "cardIDs": mapped_card_ids,
            })

            if not mapped_sections or not mapped_card_ids:
                item_issues.append({"eventCode": code, "discussionItem": echo_item})

        required_items = [{"text": title_case(item)} for item in reference_event["discussionItems"]]
        visible_sections.append({"title": "Required Procedures", "items": required_items})
        visible_sections = rewrite_event_codes(visible_sections, source_codes, code)

        title = TITLE_OVERRIDES.get(code) or source_event.get("title") or reference_event["shortTitle"]
        if code in METADATA_OVERRIDES:
            summary, overview = METADATA_OVERRIDES[code]
        elif source_event and (full_exact_reuse or primary_source == code):
            summary = source_event.get("summary", "")
            overview = source_event.get("overview", "")
        else:
            display_items = [title_case(item) for item in reference_event["discussionItems"]]
            lead = ", ".join(display_items[:3])
            if len(display_items) > 3:
                lead += ", and related event procedures"
            summary = f"Focused preparation for {lead}."
            overview = (
                f"{code} develops a briefable, source-backed understanding of {lead}. "
                "Use the discussion flow to connect recognition and setup with execution, "
                "completion cues, applicable limits, and the decisions that protect aircraft control and mission safety."
            )
        summary = rewrite_event_codes(summary, source_codes, code)
        overview = rewrite_event_codes(overview, source_codes, code)

        category_kind = category_kind_by_event_kind[reference_event["eventKind"]]
        phase_id = phase_by_category[reference_event["category"]]
        event_id = f"echo-{phase_id}-{category_kind.lower()}-{code.lower()}"
        event = {
            "id": event_id,
            "code": code,
            "title": title,
            "summary": summary,
            "overview": overview,
            "categoryKind": category_kind,
            "sourceDocuments": source_event.get("sourceDocuments", []),
            "studyNotes": {
                "headline": "Discussion Items",
                "summary": f"Prepare these items in Echo syllabus order for {code}.",
                "sections": visible_sections,
            },
            "primaryDocumentIDs": source_event.get("primaryDocumentIDs", []) if primary_source == code else [],
            "flashcardDecks": [{
                "id": f"echo-{code.lower()}-discussion-items",
                "title": f"{code} Discussion Items",
                "summary": f"Echo syllabus flashcards for {code}, reusing validated reference cards where applicable.",
                "cardIDs": list(dict.fromkeys(event_card_ids)),
            }],
            "questionBanks": source_event.get("questionBanks", []) if primary_source == code else [],
            "resourceLinks": source_event.get("resourceLinks", []),
            "videoLinks": source_event.get("videoLinks", []),
            "tags": list(dict.fromkeys([code.lower(), "echo", reference_event["category"], category_kind.lower()])),
            "syllabusSequence": reference_event["sequence"],
        }
        if source_event.get("systemsBrief") and full_exact_reuse:
            event["systemsBrief"] = copy.deepcopy(source_event["systemsBrief"])
            event["systemsBrief"]["headline"] = "Systems Brief"

        phase = next(value for value in phases if value["id"] == phase_id)
        category = next(value for value in phase["categories"] if value["kind"] == category_kind)
        category["events"].append(event)

        crosswalk_events.append({
            "code": code,
            "sequence": reference_event["sequence"],
            "sourcePages": reference_event["sourcePages"],
            "sourceEventCodes": source_codes,
            "fullExactReuse": full_exact_reuse,
            "items": item_mappings,
        })

    # All event lists use source sequence, including the two added ground events.
    for phase in phases:
        for category in phase["categories"]:
            category["events"].sort(key=lambda event: event.get("syllabusSequence", -1))

    generated_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    title_by_code = {
        event["code"]: event["title"]
        for phase in phases for category in phase["categories"] for event in category["events"]
    }
    for reference_event in echo_reference["events"]:
        reference_event["shortTitle"] = title_by_code[reference_event["code"]]
    overlay = {
        "track": "echo",
        "sourceDocumentTitle": echo_reference["sourceDocumentTitle"],
        "sourceDocumentDate": echo_reference["sourceDocumentDate"],
        "generatedAt": generated_at,
        "phases": phases,
        "flashcards": list(extra_cards.values()),
    }
    crosswalk = {
        "track": "echo",
        "generatedAt": generated_at,
        "events": crosswalk_events,
    }

    canonical_codes = {event["code"] for event in echo_reference["events"]}
    manifest_events = [
        event for phase in phases for category in phase["categories"] for event in category["events"]
        if event.get("code") in canonical_codes
    ]
    all_card_ids = set(manifest_cards) | set(extra_cards)
    missing_cards = [
        {"eventCode": event["code"], "cardID": card_id}
        for event in manifest_events
        for deck in event.get("flashcardDecks", [])
        for card_id in deck.get("cardIDs", [])
        if card_id not in all_card_ids
    ]
    duplicate_extra_card_ids = sorted(set(extra_cards) & set(manifest_cards))
    new_card_quality_issues = [
        card["id"] for card in extra_cards.values()
        if (not card.get("prompt") or len(card.get("answer", "")) < 80
            or not card.get("eventCodes") or card.get("kind") != "standard"
            or not set(card.get("tags", [])).issubset({"maneuvers", "procedures", "systems", "planning"}))
    ]
    crosswalk_by_code = {event["code"]: event for event in crosswalk_events}
    title_description_issues = []
    required_procedure_issues = []
    stale_source_code_issues = []
    crosswalk_section_issues = []
    crosswalk_deck_issues = []
    note_structure_issues = []
    systems_brief_issues = []
    for event in manifest_events:
        if (not event.get("title") or event["title"] == event["code"]
                or len(event.get("summary", "")) < 40 or len(event.get("overview", "")) < 100):
            title_description_issues.append(event["code"])
        sections = event.get("studyNotes", {}).get("sections", [])
        section_titles = [section.get("title") for section in sections]
        if (event.get("studyNotes", {}).get("headline") != "Discussion Items"
                or not sections or section_titles[-1] != "Required Procedures"
                or len([title for title in section_titles if title]) != len(set(title for title in section_titles if title))):
            note_structure_issues.append(event["code"])
        systems_brief = event.get("systemsBrief")
        if systems_brief and (
            not event["code"].startswith("FAM")
            or event["categoryKind"] != "flights"
            or systems_brief.get("headline") != "Systems Brief"
        ):
            systems_brief_issues.append(event["code"])
        required = next(
            (section for section in event["studyNotes"]["sections"] if section.get("title") == "Required Procedures"),
            None,
        )
        expected = next(value["discussionItems"] for value in echo_reference["events"] if value["code"] == event["code"])
        actual = [item["text"] for item in required.get("items", [])] if required else []
        if [normalized(value) for value in actual] != [normalized(value) for value in expected]:
            required_procedure_issues.append(event["code"])
        content_text = json.dumps({
            "title": event["title"], "summary": event["summary"],
            "overview": event["overview"], "studyNotes": event["studyNotes"],
        })
        stale = [
            source_code for source_code in crosswalk_by_code[event["code"]]["sourceEventCodes"]
            if source_code != event["code"] and source_code in content_text
        ]
        if stale:
            stale_source_code_issues.append({"eventCode": event["code"], "staleCodes": stale})
        visible_titles = {
            section.get("title") for section in event["studyNotes"]["sections"]
            if section.get("title") != "Required Procedures"
        }
        deck_ids = {
            card_id for deck in event.get("flashcardDecks", []) for card_id in deck.get("cardIDs", [])
        }
        for item in crosswalk_by_code[event["code"]]["items"]:
            missing_titles = sorted(set(item["sectionTitles"]) - visible_titles)
            if missing_titles:
                crosswalk_section_issues.append({
                    "eventCode": event["code"], "discussionItem": item["discussionItem"],
                    "missingSectionTitles": missing_titles,
                })
            missing_item_cards = sorted(set(item["cardIDs"]) - deck_ids)
            if missing_item_cards:
                crosswalk_deck_issues.append({
                    "eventCode": event["code"], "discussionItem": item["discussionItem"],
                    "missingCardIDs": missing_item_cards,
                })

    reference_sequences = [event["sequence"] for event in echo_reference["events"]]
    manifest_sequences = sorted(event.get("syllabusSequence") for event in manifest_events)
    solo_codes = sorted(event["code"] for event in echo_reference["events"] if event["isSolo"])
    checkride_codes = sorted(event["code"] for event in echo_reference["events"] if event["isCheckride"])
    audit = {
        "track": "echo",
        "generatedAt": generated_at,
        "canonicalEventCount": len(echo_reference["events"]),
        "manifestCanonicalEventCount": len(manifest_events),
        "exactEventReuseCount": sum(event["fullExactReuse"] for event in crosswalk_events),
        "canonicalDiscussionItemCount": sum(len(event["discussionItems"]) for event in echo_reference["events"]),
        "mappedDiscussionItemCount": sum(len(event["items"]) for event in crosswalk_events),
        "reusedDiscussionItemCount": sum(
            item["method"] != "new" for event in crosswalk_events for item in event["items"]
        ),
        "newDiscussionItemCount": sum(
            item["method"] == "new" for event in crosswalk_events for item in event["items"]
        ),
        "newFlashcardCount": len(extra_cards),
        "missingCanonicalEvents": sorted(canonical_codes - {event["code"] for event in manifest_events}),
        "unexpectedCanonicalEvents": sorted({event["code"] for event in manifest_events} - canonical_codes),
        "itemCoverageIssues": item_issues,
        "missingCardIDs": missing_cards,
        "duplicateExtraCardIDs": duplicate_extra_card_ids,
        "newCardQualityIssues": new_card_quality_issues,
        "eventsWithoutNotes": [event["code"] for event in manifest_events if not event.get("studyNotes")],
        "eventsWithoutDecks": [event["code"] for event in manifest_events if not event.get("flashcardDecks")],
        "titleDescriptionIssues": title_description_issues,
        "requiredProcedureIssues": required_procedure_issues,
        "staleSourceCodeIssues": stale_source_code_issues,
        "crosswalkSectionIssues": crosswalk_section_issues,
        "crosswalkDeckIssues": crosswalk_deck_issues,
        "noteStructureIssues": note_structure_issues,
        "systemsBriefIssues": systems_brief_issues,
        "sequenceIssues": [] if reference_sequences == list(range(87)) else reference_sequences,
        "manifestSequenceIssues": [] if manifest_sequences == list(range(87)) else manifest_sequences,
        "groundSchoolEventCodes": sorted(
            event["code"] for event in echo_reference["events"] if event["eventKind"] == "groundSchool"
        ),
        "soloEventCodes": solo_codes,
        "checkrideEventCodes": checkride_codes,
        "unexpectedCapstoneEvents": sorted(
            event["code"] for event in echo_reference["events"] if event["category"] == "capstone"
        ),
        "shortTitleIssues": sorted(
            event["code"] for event in echo_reference["events"]
            if event["shortTitle"] != title_by_code[event["code"]]
        ),
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    ECHO_REFERENCE.write_text(json.dumps(echo_reference, indent=2, sort_keys=True) + "\n")
    OUTPUT.write_text(json.dumps(overlay, indent=2, sort_keys=True) + "\n")
    CROSSWALK_OUTPUT.write_text(json.dumps(crosswalk, indent=2, sort_keys=True) + "\n")
    AUDIT_OUTPUT.write_text(json.dumps(audit, indent=2, sort_keys=True) + "\n")

    blocking = (
        audit["canonicalEventCount"] != 87
        or audit["manifestCanonicalEventCount"] != 87
        or audit["canonicalDiscussionItemCount"] != audit["mappedDiscussionItemCount"]
        or audit["missingCanonicalEvents"]
        or audit["itemCoverageIssues"]
        or audit["missingCardIDs"]
        or audit["duplicateExtraCardIDs"]
        or audit["newCardQualityIssues"]
        or audit["eventsWithoutNotes"]
        or audit["eventsWithoutDecks"]
        or audit["titleDescriptionIssues"]
        or audit["requiredProcedureIssues"]
        or audit["staleSourceCodeIssues"]
        or audit["crosswalkSectionIssues"]
        or audit["crosswalkDeckIssues"]
        or audit["noteStructureIssues"]
        or audit["systemsBriefIssues"]
        or audit["sequenceIssues"]
        or audit["manifestSequenceIssues"]
        or audit["groundSchoolEventCodes"] != ["F1201", "FAM1301"]
        or audit["soloEventCodes"] != ["FAM4501", "FAM4801"]
        or audit["checkrideEventCodes"] != ["F4290", "FAM4490", "FAM4790", "I4490"]
        or audit["unexpectedCapstoneEvents"]
        or audit["shortTitleIssues"]
    )
    print(f"Wrote {len(manifest_events)} Echo events and {len(extra_cards)} new flashcards.")
    if blocking:
        raise SystemExit("Echo syllabus audit failed; inspect EchoSyllabusAuditReport.json")


if __name__ == "__main__":
    main()
