#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import { webcrypto } from "node:crypto";

const PROJECT_REF = process.env.SUPABASE_PROJECT_REF || process.env.PROJECT_REF || "nsnezmbmosqtpychvpea";
const MANAGEMENT_URL = `https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth`;
const args = new Set(process.argv.slice(2));
const dryRun = args.has("--dry-run");
const skipApple = args.has("--skip-apple");

function fail(message) {
  console.error(message);
  process.exit(1);
}

function integerEnv(name, fallback, { min, max }) {
  const raw = process.env[name];
  if (!raw) {
    return fallback;
  }
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    fail(`${name} must be an integer between ${min} and ${max}.`);
  }
  return parsed;
}

function booleanEnv(name, fallback) {
  const raw = process.env[name];
  if (!raw) {
    return fallback;
  }
  if (/^(1|true|yes)$/i.test(raw)) {
    return true;
  }
  if (/^(0|false|no)$/i.test(raw)) {
    return false;
  }
  fail(`${name} must be true or false.`);
}

function includeIfPresent(payload, key, value) {
  if (value !== undefined && value !== null && value !== "") {
    payload[key] = value;
  }
}

function base64url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function pemToArrayBuffer(pem) {
  const normalized = pem.replaceAll("\\n", "\n");
  const base64 = normalized
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  return Buffer.from(base64, "base64");
}

async function readTemplate(path) {
  return readFile(new URL(`../${path}`, import.meta.url), "utf8");
}

async function readApplePrivateKey() {
  if (process.env.APPLE_PRIVATE_KEY) {
    return process.env.APPLE_PRIVATE_KEY;
  }
  if (process.env.APPLE_PRIVATE_KEY_PATH) {
    return readFile(process.env.APPLE_PRIVATE_KEY_PATH, "utf8");
  }
  return null;
}

async function generateAppleClientSecret(clientID, { allowGeneratedSecret }) {
  if (process.env.APPLE_CLIENT_SECRET) {
    return process.env.APPLE_CLIENT_SECRET;
  }
  if (!allowGeneratedSecret) {
    return null;
  }

  const teamID = process.env.APPLE_TEAM_ID;
  const keyID = process.env.APPLE_KEY_ID;
  const privateKey = await readApplePrivateKey();
  if (!teamID || !keyID || !privateKey) {
    return null;
  }

  const issuedAt = Math.floor(Date.now() / 1000);
  const maxDays = 180;
  const validDays = integerEnv("APPLE_SECRET_VALID_DAYS", 170, { min: 1, max: maxDays });
  const expiresAt = issuedAt + validDays * 24 * 60 * 60;
  const header = { alg: "ES256", kid: keyID };
  const claims = {
    iss: teamID,
    iat: issuedAt,
    exp: expiresAt,
    aud: "https://appleid.apple.com",
    sub: clientID,
  };
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const key = await webcrypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
  const signature = await webcrypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    Buffer.from(signingInput)
  );
  return `${signingInput}.${base64url(new Uint8Array(signature))}`;
}

async function buildPayload() {
  const confirmationTemplate = await readTemplate("supabase/auth/templates/confirmation.html");
  const recoveryTemplate = await readTemplate("supabase/auth/templates/recovery.html");
  const reauthenticationTemplate = await readTemplate("supabase/auth/templates/reauthentication.html");

  const payload = {
    external_email_enabled: true,
    mailer_autoconfirm: false,
    mailer_allow_unverified_email_sign_ins: false,
    mailer_otp_exp: integerEnv("SUPABASE_AUTH_OTP_EXP_SECONDS", 3600, { min: 60, max: 86400 }),
    mailer_otp_length: integerEnv("SUPABASE_AUTH_OTP_LENGTH", 6, { min: 6, max: 10 }),
    password_min_length: integerEnv("SUPABASE_AUTH_PASSWORD_MIN_LENGTH", 10, { min: 10, max: 32767 }),
    password_hibp_enabled: booleanEnv("SUPABASE_AUTH_LEAKED_PASSWORD_PROTECTION", true),
    mailer_subjects_confirmation: "{{ .Token }} is your Primary Gouge code",
    mailer_templates_confirmation_content: confirmationTemplate,
    mailer_subjects_recovery: "{{ .Token }} is your Primary Gouge reset code",
    mailer_templates_recovery_content: recoveryTemplate,
    mailer_subjects_reauthentication: "{{ .Token }} is your Primary Gouge verification code",
    mailer_templates_reauthentication_content: reauthenticationTemplate,
    mailer_notifications_password_changed_enabled: true,
    mailer_notifications_email_changed_enabled: true,
    mailer_notifications_identity_linked_enabled: true,
    mailer_notifications_identity_unlinked_enabled: true,
  };

  includeIfPresent(payload, "site_url", process.env.SUPABASE_AUTH_SITE_URL);
  includeIfPresent(payload, "uri_allow_list", process.env.SUPABASE_AUTH_URI_ALLOW_LIST);
  includeIfPresent(payload, "password_required_characters", process.env.SUPABASE_AUTH_PASSWORD_REQUIRED_CHARACTERS);

  if (!skipApple) {
    const appleClientID =
      process.env.APPLE_CLIENT_ID ||
      process.env.APPLE_SERVICES_ID ||
      process.env.APPLE_BUNDLE_ID ||
      "bolt.Primary-Gouge";
    payload.external_apple_enabled = true;
    payload.external_apple_client_id = appleClientID;
    includeIfPresent(
      payload,
      "external_apple_additional_client_ids",
      process.env.APPLE_ADDITIONAL_CLIENT_IDS
    );

    const appleSecret = await generateAppleClientSecret(appleClientID, {
      allowGeneratedSecret: Boolean(process.env.APPLE_CLIENT_ID || process.env.APPLE_SERVICES_ID),
    });
    includeIfPresent(payload, "external_apple_secret", appleSecret);
  }

  return payload;
}

function redacted(payload) {
  const copy = { ...payload };
  if (copy.external_apple_secret) {
    copy.external_apple_secret = "<redacted>";
  }
  return copy;
}

async function patchAuthConfig(payload) {
  const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
  if (!accessToken) {
    fail("SUPABASE_ACCESS_TOKEN is required unless you run with --dry-run.");
  }

  const response = await fetch(MANAGEMENT_URL, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  const text = await response.text();
  let body = text;
  try {
    body = JSON.parse(text);
  } catch {
    // Keep the raw body.
  }

  if (!response.ok) {
    console.error(JSON.stringify(redacted(payload), null, 2));
    fail(`Supabase Auth config update failed (${response.status}): ${JSON.stringify(body)}`);
  }

  console.log(`Updated Supabase Auth config for ${PROJECT_REF}.`);
  console.log(`Patched keys: ${Object.keys(payload).sort().join(", ")}`);
}

const payload = await buildPayload();

if (dryRun) {
  console.log(JSON.stringify(redacted(payload), null, 2));
  if (!process.env.SUPABASE_ACCESS_TOKEN) {
    console.error("\nDry run only. Set SUPABASE_ACCESS_TOKEN to apply this payload.");
  }
  if (!skipApple && !payload.external_apple_secret) {
    console.error(
      "Apple is enabled with a client id only. Set APPLE_CLIENT_SECRET or APPLE_TEAM_ID, APPLE_KEY_ID, and APPLE_PRIVATE_KEY_PATH if this project uses Apple's OAuth/Services ID flow."
    );
  }
} else {
  await patchAuthConfig(payload);
}
