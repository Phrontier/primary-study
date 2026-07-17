import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.95.0";

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), { status, headers: jsonHeaders });
}

function base64URL(value: string | Uint8Array): string {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function pkcs8Bytes(pem: string): Uint8Array {
  const normalized = pem.replace(/\\n/g, "\n");
  const encoded = normalized
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(encoded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

async function appleClientSecret(): Promise<string> {
  const teamID = Deno.env.get("APPLE_TEAM_ID");
  const keyID = Deno.env.get("APPLE_KEY_ID");
  const privateKey = Deno.env.get("APPLE_PRIVATE_KEY");
  const clientID = Deno.env.get("APPLE_CLIENT_ID") ?? Deno.env.get("APP_BUNDLE_ID");
  if (!teamID || !keyID || !privateKey || !clientID) {
    throw new Error("Sign in with Apple deletion is not configured.");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = base64URL(JSON.stringify({ alg: "ES256", kid: keyID }));
  const payload = base64URL(JSON.stringify({
    iss: teamID,
    iat: now,
    exp: now + 300,
    aud: "https://appleid.apple.com",
    sub: clientID,
  }));
  const decodedKey = pkcs8Bytes(privateKey);
  const keyData = new Uint8Array(decodedKey.byteLength);
  keyData.set(decodedKey);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData.buffer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${payload}`),
  );
  return `${header}.${payload}.${base64URL(new Uint8Array(signature))}`;
}

async function revokeAppleAuthorization(authorizationCode: string): Promise<void> {
  const clientID = Deno.env.get("APPLE_CLIENT_ID") ?? Deno.env.get("APP_BUNDLE_ID");
  if (!clientID) throw new Error("APPLE_CLIENT_ID is not configured.");
  const clientSecret = await appleClientSecret();
  const tokenResponse = await fetch("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientID,
      client_secret: clientSecret,
      code: authorizationCode,
      grant_type: "authorization_code",
    }),
  });
  if (!tokenResponse.ok) throw new Error(`Apple token exchange failed (${tokenResponse.status}).`);

  const tokenPayload = await tokenResponse.json() as {
    refresh_token?: string;
    access_token?: string;
  };
  const token = tokenPayload.refresh_token ?? tokenPayload.access_token;
  if (!token) throw new Error("Apple did not return a revocable token.");

  const revokeResponse = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientID,
      client_secret: clientSecret,
      token,
    }),
  });
  if (!revokeResponse.ok) throw new Error(`Apple token revocation failed (${revokeResponse.status}).`);
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }

  if (request.method !== "POST" && request.method !== "DELETE") {
    return jsonError("Method not allowed.", 405);
  }

  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonError("Sign-in is required.", 401);
  }

  const supabaseURL = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseURL || !anonKey || !serviceRoleKey) {
    return jsonError("Supabase function environment is not configured.", 500);
  }

  const userClient = createClient(supabaseURL, anonKey, {
    global: {
      headers: {
        authorization,
      },
    },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    return jsonError("Sign-in is required.", 401);
  }

  const body = await request.json().catch(() => ({})) as { appleAuthorizationCode?: unknown };
  const providers = Array.isArray(data.user.app_metadata?.providers)
    ? data.user.app_metadata.providers
    : [data.user.app_metadata?.provider].filter(Boolean);
  const usesApple = providers.includes("apple");
  if (usesApple) {
    if (typeof body.appleAuthorizationCode !== "string" || !body.appleAuthorizationCode) {
      return jsonError("Confirm with Apple before deleting this account.", 400);
    }
    try {
      await revokeAppleAuthorization(body.appleAuthorizationCode);
    } catch (error) {
      console.error("apple-account-revocation", error);
      return jsonError("Apple authorization could not be revoked. Please try again.", 502);
    }
  }

  // Revoke all Supabase sessions before removing the user record. Deleting a
  // user alone does not immediately invalidate already-issued access tokens.
  const logoutResponse = await fetch(`${supabaseURL}/auth/v1/logout?scope=global`, {
    method: "POST",
    headers: {
      apikey: anonKey,
      authorization,
    },
  });
  if (!logoutResponse.ok && logoutResponse.status !== 401) {
    return jsonError("Account sessions could not be revoked.", 500);
  }

  const adminClient = createClient(supabaseURL, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(data.user.id);
  if (deleteError) {
    return jsonError("Account could not be deleted.", 500);
  }

  return new Response(null, { status: 204 });
});
