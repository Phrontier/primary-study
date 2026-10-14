# Apple signed-data verifier

Isolated verification service for Primary Gouge. Production entrypoint is src/index.ts. Apple’s pinned 3.1.0 library performs certificate-chain, app/environment, JWS, expiry and online OCSP checks. Library import is request-scoped because its dependency generates randomness during initialization. The native-fetch adapter supplies node-fetch response.buffer() and transport semantics without changing signature or revocation validation.

POST /verify requires a dedicated server-only APPLE_VERIFIER_TOKEN bearer credential. It accepts kind=transaction|renewal|notification and signedPayload, returning {version:1,kind,payload}. Missing auth: 401; malformed/oversize request: 400/413; invalid signed data: 422; transient failure: 503. Worker holds no Supabase database credentials or Apple private key. Only Apple G2/G3 production roots are trusted. Xcode and LocalTesting are rejected.

Supabase keeps existing endpoints, Auth.getUser(token), ownership rules, and atomic persistence. APPLE_VERIFIER_URL must equal the fixed deployed HTTPS /verify URL; redirects are rejected and requests time out after 40 seconds. Secrets stay outside source control.

Run npm ci, npm run check, npm test. tests/runtime-entry.ts is a local-only real-chain/OCSP probe and must never be deployed as the production entrypoint. Test roots/fixtures are never imported by src/index.ts. A local-network OCSP transport failure does not establish production failure; verify on the deployed Worker before connecting Supabase.

Live rollout October 13, 2026: Worker certificate/online-revocation verification reached JWS signature rejection for an intentionally invalid signature using Apple’s real certificate chain. Unauthorized requests returned 401. Supabase subscription-entitlement v9 and apple-subscription-notifications v6 deployed. Real purchase persistence and full lifecycle tests remain separate gates.

Rollback: retain fail-closed behavior; never revert to accepting unverified claims or disable online checks. Restore a known working Worker version and matching Supabase client version together. Alert on verification_unavailable or persistent synchronization failure, then investigate before granting any manual access.
