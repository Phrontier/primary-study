# Approved redesign — TestFlight release

October 22, 2026. The user approved the complete native gallery and authorized promotion to main and TestFlight distribution.

## Source preservation

- Approved implementation: `626d908d54b520a4c20d00e4de1975d16f19e711`. Main was fast-forwarded and pushed without rewriting history.
- Prior main is preserved and pushed as `codex/main-before-design-2026-10-22` (`ff3f3b8`).
- Pre-redesign checkpoint remains `codex/pre-redesign-snapshot-2026-10-13` (`523833b`), also pushed.
- Every other original local branch retained its original SHA. The design branch remains available as `codex/complete-redesign`.
- Complete pre-promotion Git bundle verified at `/tmp/primary-gouge-pre-release-2026-10-22.bundle`; temporary local safety backup, not a permanent release artifact.

## Candidate

- Version 1.0 (3), bundle `bolt.Primary-Gouge`, existing team and automatic signing.
- All 107 deterministic tests passed; see `Evidence/design-build3-tests-oct22.json`. Local StoreKit integration is excluded as previously documented.
- Swift source fingerprint matches the approved gallery build exactly: `645b395e8e9b63e0390d51557f28b19884874d78802e796c7fc4e488183d54ed` (70 files).
- Signed Release archive succeeded. Debug gallery symbols/launch flag absent. All 114 manifest resource paths present.
- Archive: `/tmp/PrimaryGouge-Design-Build3.xcarchive`.
- Initial upload reached completion but Apple rejected the expired Xcode account session. See `Evidence/design-build3-upload-expired-oct22.log`. After the owner refreshed Xcode sign-in, the same archive uploaded successfully. Apple accepted the package for processing at 18:38:39 in the Mac upload log. See `Evidence/design-build3-upload-success-oct22.log`. Processing completed. Build 1.0 (3) was assigned to the existing Release Verification internal group (one existing tester), and the group build list confirms **Testing**. Evidence: `Evidence/design-build3-testing-oct22.png`. What to Test notes were saved. Apple build ID: `06dc2ab1-8f41-4835-9f91-96b8cc798e51`.

Physical-phone testing and external-service checks remain separate from simulator tests. This is a TestFlight release, not an App Store submission.

## Install

Open TestFlight on the existing tester’s iPhone → Primary Gouge → Update, and verify version 1.0 (3). The new design is on main and the existing tester has access. App Store submission was not performed.
