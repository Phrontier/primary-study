# Discussion Item Authoring Progress

Use this tracker as the durable resume point for category-wide discussion-item authoring. Update it after each completed event and whenever source assumptions or blockers change.

## Active pass

- Active category: Instruments
- Category key in `SyllabusEventReference.json`: `instruments`
- Status: I62 Radio Instruments complete through `I6201`
- Current event: `I6202`
- Next action: author `I6202` from canonical syllabus items, local VTD/sim sources, Instrument Flight Planning Workbook weather-source material, CNAF weather-briefing rules, Instrument Navigation FTI approach/weather decision material, and prior Instrument weather/NOTAM standards.
- Last validated event: `I6201`
- Last event commit: use `git log --oneline -- Primary\ Gouge/AppContent/EventContentOverrides/I6201.json`
- Last manifest validation: `I6201` authored; no `I6201` coverage issues; `discussionItemAuthoringIssues` is `0`
- Last build-for-testing: passed for `I6201`
- Systems brief policy: prohibited for Instruments

## Instruments source profile

- Canonical event source: `Primary Gouge/AppContent/SyllabusEventReference.json`
- Local source root: `Contents/2. INSTRUMENTS`
- Primary technical authority: `Pubs/Instrument Navigation FTI  P-765 CH-4.pdf`
- Planning/regulatory references:
  - `Pubs/Instrument Flight Planning Workbook Rev1.pdf`
  - `/Users/conwaybolt/Library/CloudStorage/OneDrive-Personal/Documents/Marine Corps/Flight School/MATSG-22/Pubs/cnaf-3710.7 General NATOPS.pdf`
  - `/Users/conwaybolt/Library/CloudStorage/OneDrive-Personal/Documents/Marine Corps/Flight School/MATSG-22/Pubs/KNGP IFG FY25v1.2.pdf`
  - `/Users/conwaybolt/Library/CloudStorage/OneDrive-Personal/Documents/Marine Corps/Flight School/MATSG-22/Pubs/NATOPS A1-T6BAA-NFM-100 CH 2.pdf`
  - `Primary Gouge/AppContent/XMLSources/T-6 EP's.xml`
  - `Primary Gouge/AppContent/XMLSources/EP's N_W_C.xml`
- Event-specific sources:
  - local event `.docx` files
  - briefing-guide PDFs
  - scenario PDFs
  - approach plates
  - 1801 and 1801C files
  - jet logs and jet-log templates
  - DK gouge mirrors when useful for clarity
- Source policy:
  - `SyllabusEventReference.json` controls exact discussion-item membership and order.
  - Instrument Navigation FTI controls instrument procedures, approach flow, scan work, holding, en route procedures, and standards.
  - Flight Planning Workbook, CNAF 3710.7, IFG, NATOPS, and EP/N/W/C XML control planning, regulatory, local-field, aircraft, and emergency-procedure details when relevant.
  - Local event docs provide event emphasis and student-facing organization.
  - Do not author `systemsBrief` for any Instrument event.

## Known blockers and cautions

- Current build validation is still FAM-oriented in code; apply the shared authoring standard manually until category-wide validation is generalized.
- `I2101` through `I6201` now have authored Instrument event content overrides.
- Remaining pending Instrument events still use generic manifest scaffold notes until authored.
- Some flight `.docx` files are hidden from app source-document cards but remain valid authoring sources via `textutil`.
- Treat local field names, routes, frequencies, and scenario-specific details as day-of/local verification material unless the item is inherently local.
- For cumulative `any emergency procedure` items, do not invent an exhaustive EP list without source support; frame the study method and decision tree from canonical EP/N/W/C sources.

## Event order

| Event | Title | Media | Kind | Block | Items | Status | Commit | Notes |
| --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| I2101 | Instrument Scan Patterns | UTD | sim | I21 Basic Instruments | 6 | complete | use git log | Authored from syllabus membership, local event docs, briefing guide, and Instrument Navigation FTI; no `systemsBrief`; manifest/audit/build passed. |
| I2102 | IMC Emergencies | UTD | sim | I21 Basic Instruments | 3 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, Instrument Navigation FTI, and NATOPS emergency guidance; no `systemsBrief`; manifest/audit/build passed. |
| I2103 | Approach Maneuver | UTD | sim | I21 Basic Instruments | 5 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, Instrument Navigation FTI, NATOPS IAC failure, and BFI references; no `systemsBrief`; manifest/audit/build passed. |
| I2201 | HSI Orientation | UTD | sim | I22 Radio Instruments | 6 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, and Instrument Navigation FTI; no `systemsBrief`; manifest/audit/build passed. |
| I2202 | Arcing and Radial Intercepts | UTD | sim | I22 Radio Instruments | 6 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI, NATOPS OBOGS material, and EP/N/W/C XML; no `systemsBrief`; manifest/audit/build passed. |
| I2203 | Holding Entry | UTD | sim | I22 Radio Instruments | 4 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI holding material, and NATOPS battery/generator failure guidance; no `systemsBrief`; manifest/audit/build passed. |
| I3101 | Clearance and Departure Procedures | OFT | sim | I31 Radio Instruments | 6 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI departure/enroute/approach material, and CNAF takeoff/approach minimums; no `systemsBrief`; manifest/audit/build passed. |
| I3102 | HILO Approaches | OFT | sim | I31 Radio Instruments | 5 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI HILO/holding/intersection material, and NATOPS/EP oil-system malfunction guidance; no `systemsBrief`; manifest/audit/build passed. |
| I3103 | PAR | OFT | sim | I31 Radio Instruments | 6 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI radar-approach material, prior IMC-emergency wording decision, and NATOPS propeller malfunction guidance; no `systemsBrief`; manifest/audit/build passed. |
| I3104 | Night Cockpit Setup | OFT | sim | I31 Radio Instruments | 6 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI SID/RVFAC/ILS/LOC/PTP material, night cockpit setup references, and EP/N/W/C fuel-system malfunction guidance; no `systemsBrief`; manifest/audit/build passed. |
| I3201 | GPS Procedures | UTD | sim | I32 Radio Instruments | 5 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, and Instrument Navigation FTI GPS/RNAV/TAA material; no `systemsBrief`; manifest/audit/build passed. |
| I3202 | STAR | UTD | sim | I32 Radio Instruments | 5 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI STAR/departure/RNAV material, and clearance-planning references; no `systemsBrief`; manifest/audit/build passed. |
| I3203 | No-Gyro Approach | OFT | sim | I32 Radio Instruments | 1 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI no-gyro approach material, and BFI/avionics failure references; no `systemsBrief`; manifest/audit/build passed. |
| I3204 | High-Altitude Approach | OFT | sim | I32 Radio Instruments | 1 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, and Instrument Navigation FTI high-altitude approach/non-radar communication material; no `systemsBrief`; manifest/audit/build passed. |
| I3205 | Avionics Failures | OFT | sim | I32 Radio Instruments | 3 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI ODP/procedure-turn/ILS material, and NATOPS avionics-failure references; no `systemsBrief`; manifest/audit/build passed. |
| I3206 | En Route Fuel Management | OFT | sim | I32 Radio Instruments | 4 | complete | use git log | Authored from syllabus membership, local event doc, briefing guide, scenario guide, Instrument Navigation FTI feeder/reverse-sensing material, and Instrument Flight Planning Workbook fuel-management material; no `systemsBrief`; manifest/audit/build passed. |
| I4101 | CRM and Holding | T-6B | flight | I41 Radio Instruments | 3 | complete | use git log | Authored from syllabus membership, local flight event docs, CNAF/NATOPS CRM and TEM material, and Instrument Navigation FTI holding/VOR approach material; no `systemsBrief`; manifest/audit/build passed. |
| I4102 | ILS and LOC Approaches | T-6B | flight | I41 Radio Instruments | 3 | complete | use git log | Authored from syllabus membership, local flight event docs, Instrument Navigation FTI ILS/LOC/RVFAC material, and NATOPS icing references; no `systemsBrief`; manifest/audit/build passed. |
| I4103 | PAR, ASR, and No-Gyro | T-6B | flight | I41 Radio Instruments | 4 | complete | use git log | Authored from syllabus membership, local flight event docs, Instrument Navigation FTI radar/no-gyro material, NATOPS thunderstorm and OBOGS references, and EP/N/W/C XML; no `systemsBrief`; manifest/audit/build passed. |
| I4201 | Departure Procedures and Airway Navigation | T-6B | flight | I42 Radio Instruments | 4 | complete | use git log | Authored from syllabus membership, local flight event docs, Instrument Navigation FTI departure/en route/radar lost-comm material, KNGP IFG coded-route/local lost-comm references, and current eCFR 91.181/91.185 cross-check; no `systemsBrief`; manifest/audit/build passed. |
| I4202 | FMS Arrivals | T-6B | flight | I42 Radio Instruments | 1 | complete | use git log | Authored from syllabus membership, local flight event docs, NATOPS FMS route/procedure management material, and Instrument Navigation FTI RNAV/TAA/GPS approach material; no `systemsBrief`; manifest/audit/build passed. |
| I4203 | No-Gyro and Fuel Management | T-6B | flight | I42 Radio Instruments | 3 | complete | use git log | Authored from syllabus membership, local flight event docs, Instrument Navigation FTI no-gyro material, Navigation FTI emergency field/route-abort guidance, CNAF fuel planning requirements, Instrument Flight Planning Workbook fuel-management material, and NATOPS endurance data; no `systemsBrief`; manifest/audit/build passed. |
| I4204 | Takeoff and Alternate Minimums | T-6B | flight | I42 Radio Instruments | 1 | complete | use git log | Authored from syllabus membership, local flight event docs, CNAF M-3710.7 takeoff/approach/alternate filing minimums, Instrument Flight Planning Workbook weather and alternate-planning material, and Instrument Navigation FTI GPS-alternate restrictions; no `systemsBrief`; manifest/audit/build passed. |
| I4301 | Flight Planning and Jet Logs | T-6B | flight | I43 Instrument Navigation | 8 | complete | use git log | Authored from syllabus membership, local flight event docs, CNAF preflight/flight-plan/weather/minimums/airfield guidance, Instrument Flight Planning Workbook weather/flight-log/DD-1801 material, Instrument Navigation FTI GPS-alternate restrictions, and NATOPS strange-field servicing/security procedures; no `systemsBrief`; manifest/audit/build passed. |
| I4302 | En Route Weather and Circling | T-6B | flight | I43 Instrument Navigation | 6 | complete | use git log | Authored from syllabus membership, local flight event docs, Instrument Flight Planning Workbook en route weather and IFR Supplement material, Instrument Navigation FTI circling/VDP/missed-approach and DRAFT guidance, and prior fuel-management consistency; no `systemsBrief`; manifest/audit/build passed. |
| I4303 | Airspace and Field Selection | T-6B | flight | I43 Instrument Navigation | 5 | complete | use git log | Authored from syllabus membership, local flight event docs, FAA/AIM airspace classification references, Instrument Navigation FTI high-altitude approach material, Navigation FTI route-abort/emergency-field guidance, NATOPS recovery/FMS/endurance data, CNAF minimum-fuel rules, and Instrument Flight Planning Workbook fuel values; no `systemsBrief`; manifest/audit/build passed. |
| I4304 | Lost Communications and SID/STAR | T-6B | flight | I43 Instrument Navigation | 6 | complete | use git log | Authored from syllabus membership, local flight event docs, current eCFR/AIM lost-communication references, Instrument Navigation FTI lost-communications/SID/STAR/departure guidance, Instrument Flight Planning Workbook STAR/ODP/Trouble T material, and cumulative EP review rules; no `systemsBrief`; manifest/audit/build passed. |
| I4490 | Instrument Check Flight | T-6B | flight | I44 Instrument Check Flight | 7 | complete | use git log | Authored from syllabus membership, local check-flight event docs, DD-1801/DD-1801-C/jet-log source files, current eCFR/AIM lost-communications references, CNAF takeoff/approach/flight-planning rules, Instrument Flight Planning Workbook DD-1801/stopover/NOTAM/weather material, and prior Instrument event coverage; no `systemsBrief`; manifest/audit/build passed. |
| I6101 | Procedure Turns and Missed Approach | VTD | sim | I61 Radio Instruments | 7 | complete | use git log | Authored from syllabus membership, local VTD event doc, scenario guide, Instrument Navigation FTI departure/procedure-turn/teardrop/HILO/final-approach/VDP/missed-approach material, NATOPS instrument-approach airspeed guidance, and prior Instrument procedure standards; no `systemsBrief`; manifest/audit/build passed. |
| I6102 | Arcing and Holding | VTD | sim | I61 Radio Instruments | 6 | complete | use git log | Authored from syllabus membership, local VTD event doc, scenario guide, Instrument Navigation FTI arcing/RVFAC/ILS/LOC/holding/shuttle-descent material, and prior Instrument radio-instrument standards; no `systemsBrief`; manifest/audit/build passed. |
| I6201 | CNAF M-3710.7 Minimum Fuel Requirements | VTD | sim | I62 Radio Instruments | 7 | complete | use git log | Authored from syllabus membership, local VTD event doc, scenario guide, CNAF M-3710.7 fuel/TFR planning rules, Instrument Flight Planning Workbook NOTAM material, Instrument Navigation FTI GPS/RNAV material, NATOPS maximum-endurance data, and prior Instrument fuel/GPS standards; no `systemsBrief`; manifest/audit/build passed. |
| I6202 | En Route Weather Sources | VTD | sim | I62 Radio Instruments | 6 | pending | - | - |
| I6301 | EPs and NWCs | VTD | sim | I63 Radio Instruments | 1 | pending | - | - |

## Tracker update rules

- Change one event to `in_progress` only while actively authoring it.
- Change an event to `complete` only after manifest rebuild, audit inspection, build-for-testing, commit, and push requirements for the active pass are satisfied.
- Use `git log` as the durable source for completed event commit hashes; do not amend a completed event commit only to write its own hash into this tracker.
- Keep `Current event`, `Next action`, `Last validated event`, `Last event commit`, `Last manifest validation`, and `Last build-for-testing` current after each event.
- Add source conflicts, local-procedure decisions, and event-specific exceptions to `Known blockers and cautions` or the event row notes.
