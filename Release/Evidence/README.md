# Release evidence — October 4, 2026

`iphone-current.json` is the final iPhone 17 Pro/iOS 26.4.1 test-result summary. The console reports 104 Swift Testing tests and 10 XCTest UI tests passed. The real StoreKitIntegrationTests class is deliberately excluded from this run and remains a separate failing release gate. XCTest's top-level summary can count suites differently; do not interpret a successful deterministic run as an Apple-signed transaction test.

`ipad-current.json` records the final iPad Pro 13 M5/iOS 26.4.1 run: 104 unit tests and 12 UI tests passed. The final unsigned Release device build also passed.

`iphone-before-final-account-reset.json` and `ipad-ui-before-final-account-reset.json` preserve earlier successful run summaries. `app-store-draft.png` and `app-information.png` show saved draft metadata and categories. These contain no reviewer credentials or Apple private keys.

Full diagnostic xcresult bundles remain under `/tmp`; they may be removed by the OS. Current production deployment IDs and unresolved gates are recorded in ../../APP_STORE_SUBMISSION.md.
