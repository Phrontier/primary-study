# Apple verifier runtime investigation — October 13, 2026

Production notifications fail in @apple/app-store-server-library 3.1.0 at crypto.X509Certificate.prototype.toString. Upstream source uses the method both in certificate caching and OCSP validation, including certificates instantiated inside the OCSP handler.

A public Apple G3 root certificate probe on Deno 2.1.4 reproduced unsupported toString, raw, infoAccess, and verify. This is a compatibility reproduction, not a claim that the production runtime version has been independently measured. Official Deno source confirms those operations are unimplemented in that version.

The proposed cache-key-only adapter cannot resolve the full verification path. No adapter was deployed and no signature, chain, expiry, or revocation check was disabled.

Recommended revised implementation: use an isolated Cloudflare Worker with Node compatibility for Apple's unchanged official verifier. Existing Supabase endpoints continue authentication, account ownership, and atomic persistence; they call the verifier over HTTPS. Validate transaction/renewal/notification payloads with pinned Apple roots, bundle and environment checks, online revocation checks, bounded payload size, and fail-closed transport handling. Responses are never accepted from user-provided verifier URLs. Add real certificate/JWS fixtures and live-runtime compatibility tests before deployment. Do not place Supabase service-role credentials in the verifier.

Cloudflare documents full node:crypto support with specific exceptions unrelated to X509 verification: https://developers.cloudflare.com/workers/runtime-apis/nodejs/crypto/
Apple verifier source: https://github.com/apple/app-store-server-library-node/blob/v3.1.0/jws_verification.ts
Deno implementation: https://github.com/denoland/deno/blob/v2.1.4/ext/node/polyfills/internal/crypto/x509.ts

Backend purchase verification remains blocked. Local Premium unlock is not a backend pass.
