# Discussion Item Authoring Progress

Use this tracker as the durable resume point for category-wide discussion-item authoring. Update it after each completed event and whenever source assumptions or blockers change.

## Active pass

- Active category: Instruments
- Category key in `SyllabusEventReference.json`: `instruments`
- Status: not started
- Current event: `I2101`
- Next action: author `I2101` discussion-item override from canonical syllabus items, local event sources, and Instrument Navigation FTI.
- Last validated event: none
- Last event commit: none
- Last manifest validation: not run for Instruments authoring
- Last build-for-testing: not run for Instruments authoring
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
- Instruments currently have no `I*.json` event content overrides.
- All 33 Instrument events currently use generic manifest scaffold notes, so every event in this tracker is pending actual authoring.
- Some flight `.docx` files are hidden from app source-document cards but remain valid authoring sources via `textutil`.
- Treat local field names, routes, frequencies, and scenario-specific details as day-of/local verification material unless the item is inherently local.
- For cumulative `any emergency procedure` items, do not invent an exhaustive EP list without source support; frame the study method and decision tree from canonical EP/N/W/C sources.

## Event order

| Event | Title | Media | Kind | Block | Items | Status | Commit | Notes |
| --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| I2101 | Instrument Scan Patterns | UTD | sim | I21 Basic Instruments | 6 | pending | - | Start here. |
| I2102 | IMC Emergencies | UTD | sim | I21 Basic Instruments | 3 | pending | - | - |
| I2103 | Approach Maneuver | UTD | sim | I21 Basic Instruments | 5 | pending | - | - |
| I2201 | HSI Orientation | UTD | sim | I22 Radio Instruments | 6 | pending | - | - |
| I2202 | Arcing and Radial Intercepts | UTD | sim | I22 Radio Instruments | 6 | pending | - | - |
| I2203 | Holding Entry | UTD | sim | I22 Radio Instruments | 4 | pending | - | - |
| I3101 | Clearance and Departure Procedures | OFT | sim | I31 Radio Instruments | 6 | pending | - | - |
| I3102 | HILO Approaches | OFT | sim | I31 Radio Instruments | 5 | pending | - | - |
| I3103 | PAR | OFT | sim | I31 Radio Instruments | 6 | pending | - | - |
| I3104 | Night Cockpit Setup | OFT | sim | I31 Radio Instruments | 6 | pending | - | - |
| I3201 | GPS Procedures | UTD | sim | I32 Radio Instruments | 5 | pending | - | - |
| I3202 | STAR | UTD | sim | I32 Radio Instruments | 5 | pending | - | - |
| I3203 | No-Gyro Approach | OFT | sim | I32 Radio Instruments | 1 | pending | - | - |
| I3204 | High-Altitude Approach | OFT | sim | I32 Radio Instruments | 1 | pending | - | - |
| I3205 | Avionics Failures | OFT | sim | I32 Radio Instruments | 3 | pending | - | - |
| I3206 | En Route Fuel Management | OFT | sim | I32 Radio Instruments | 4 | pending | - | - |
| I4101 | CRM and Holding | T-6B | flight | I41 Radio Instruments | 3 | pending | - | - |
| I4102 | ILS and LOC Approaches | T-6B | flight | I41 Radio Instruments | 3 | pending | - | - |
| I4103 | PAR, ASR, and No-Gyro | T-6B | flight | I41 Radio Instruments | 4 | pending | - | - |
| I4201 | Departure Procedures and Airway Navigation | T-6B | flight | I42 Radio Instruments | 4 | pending | - | - |
| I4202 | FMS Arrivals | T-6B | flight | I42 Radio Instruments | 1 | pending | - | - |
| I4203 | No-Gyro and Fuel Management | T-6B | flight | I42 Radio Instruments | 3 | pending | - | - |
| I4204 | Takeoff and Alternate Minimums | T-6B | flight | I42 Radio Instruments | 1 | pending | - | - |
| I4301 | Flight Planning and Jet Logs | T-6B | flight | I43 Instrument Navigation | 8 | pending | - | - |
| I4302 | En Route Weather and Circling | T-6B | flight | I43 Instrument Navigation | 6 | pending | - | - |
| I4303 | Airspace and Field Selection | T-6B | flight | I43 Instrument Navigation | 5 | pending | - | - |
| I4304 | Lost Communications and SID/STAR | T-6B | flight | I43 Instrument Navigation | 6 | pending | - | - |
| I4490 | Instrument Check Flight | T-6B | flight | I44 Instrument Check Flight | 7 | pending | - | - |
| I6101 | Procedure Turns and Missed Approach | VTD | sim | I61 Radio Instruments | 7 | pending | - | - |
| I6102 | Arcing and Holding | VTD | sim | I61 Radio Instruments | 6 | pending | - | - |
| I6201 | CNAF M-3710.7 Minimum Fuel Requirements | VTD | sim | I62 Radio Instruments | 7 | pending | - | - |
| I6202 | En Route Weather Sources | VTD | sim | I62 Radio Instruments | 6 | pending | - | - |
| I6301 | EPs and NWCs | VTD | sim | I63 Radio Instruments | 1 | pending | - | - |

## Tracker update rules

- Change one event to `in_progress` only while actively authoring it.
- Change an event to `complete` only after manifest rebuild, audit inspection, build-for-testing, commit, and push requirements for the active pass are satisfied.
- Use `git log` as the durable source for completed event commit hashes; do not amend a completed event commit only to write its own hash into this tracker.
- Keep `Current event`, `Next action`, `Last validated event`, `Last event commit`, `Last manifest validation`, and `Last build-for-testing` current after each event.
- Add source conflicts, local-procedure decisions, and event-specific exceptions to `Known blockers and cautions` or the event row notes.
