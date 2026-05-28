export interface Env {
  DB: D1Database;
  AI?: {
    run: (model: string, input: Record<string, unknown>) => Promise<unknown>;
  };
  MODERATOR_SESSION_SECRET: string;
  ACCESS_TOKEN_TTL_SECONDS?: string;
  REFRESH_TOKEN_TTL_SECONDS?: string;
  AUTO_MODERATION_MAX_BATCH?: string;
  ENABLE_AI_MODERATION?: string;
  AI_MODERATION_MODEL?: string;
}

type ReviewStatus = "pending" | "approved" | "rejected";
type EventKind = "sim" | "flight";
type ReportStatus = "open" | "dismissed" | "resolved";
type ReportTargetKind = "instructor" | "review";
type ModerationState = "queued" | "screened_clean" | "needs_human_review" | "auto_rejected";
type ModeratorAction = "allow" | "review" | "reject";

type ReviewRecord = {
  id: string;
  instructorName: string;
  squadronID: string;
  eventName: string | null;
  eventKind: EventKind;
  chillScore: number;
  gradingScore: number;
  reviewText: string;
  submittedAt: string;
  status: ReviewStatus;
  submitterClientID: string | null;
  updatedAt: string;
};

type ReportRecord = {
  id: string;
  targetKind: ReportTargetKind;
  instructorID: string;
  reviewID: string | null;
  instructorName: string;
  squadronID: string;
  eventName: string | null;
  eventKind: EventKind | null;
  reviewText: string | null;
  reasonTitle: string;
  note: string | null;
  submittedAt: string;
  status: ReportStatus;
  submitterClientID: string | null;
  updatedAt: string;
};

type SubmissionStatusRecord = {
  id: string;
  status: ReviewStatus;
  updatedAt: string;
};

type ReportStatusRecord = {
  id: string;
  status: ReportStatus;
  updatedAt: string;
};

type SessionClaims = {
  email: string;
  type: "access" | "refresh";
  exp: number;
};

type ModerationDecision = {
  action: ModeratorAction;
  summary: string;
};

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};

const profanityPatterns = [
  /\bf+u+c+k+\b/i,
  /\bshit+\b/i,
  /\basshole\b/i,
  /\bbitch\b/i,
  /\bcunt\b/i,
  /\bnigg(er|a)\b/i,
  /\bfag(got)?\b/i,
  /\bretard(ed)?\b/i,
  /\bkill yourself\b/i,
  /\bkys\b/i,
  /\bslut\b/i,
];

const spamPatterns = [
  /(.)\1{8,}/,
  /\b(?:http|www\.)/i,
  /\b(?:buy now|click here|promo code)\b/i,
];

export default {
  async fetch(request, env, ctx): Promise<Response> {
    try {
      const url = new URL(request.url);
      const path = url.pathname.replace(/\/+$/, "");

      if (request.method === "GET" && path === "/health") {
        return json({ ok: true, service: "instructor-reviews-backend" });
      }

      if (request.method === "GET" && path === "/v1/reviews/published") {
        return json({ reviews: await fetchPublishedReviews(env) });
      }

      if (request.method === "GET" && path === "/v1/submissions/statuses") {
        const clientID = requireSubmitterClientID(request);
        return json({ statuses: await fetchSubmissionStatuses(env, clientID) });
      }

      if (request.method === "GET" && path === "/v1/reports/statuses") {
        const clientID = requireSubmitterClientID(request);
        return json({ statuses: await fetchReportStatuses(env, clientID) });
      }

      if (request.method === "POST" && path === "/v1/submissions") {
        const clientID = requireSubmitterClientID(request);
        const payload = (await request.json()) as ReviewRecord;
        const created = await createSubmission(env, payload, clientID);
        return json({ id: created.id }, 201);
      }

      if (request.method === "POST" && path === "/v1/reports") {
        const clientID = requireSubmitterClientID(request);
        const payload = (await request.json()) as ReportRecord;
        const created = await createReport(env, payload, clientID);
        return json({ id: created.id }, 201);
      }

      if (request.method === "POST" && path === "/v1/moderator/sign-in") {
        const payload = (await request.json()) as { email?: string; password?: string };
        const session = await signInModerator(env, payload.email ?? "", payload.password ?? "");
        return json(session);
      }

      if (request.method === "POST" && path === "/v1/moderator/refresh") {
        const payload = (await request.json()) as { refreshToken?: string };
        const session = await refreshModerator(env, payload.refreshToken ?? "");
        return json(session);
      }

      if (request.method === "GET" && path === "/v1/moderation/queue") {
        await requireModerator(env, request);
        return json(await fetchModerationQueue(env));
      }

      const approveMatch = path.match(/^\/v1\/moderation\/submissions\/([^/]+)\/approve$/);
      if (request.method === "POST" && approveMatch) {
        await requireModerator(env, request);
        await approveSubmission(env, decodeURIComponent(approveMatch[1]));
        return new Response(null, { status: 204 });
      }

      const rejectMatch = path.match(/^\/v1\/moderation\/submissions\/([^/]+)\/reject$/);
      if (request.method === "POST" && rejectMatch) {
        await requireModerator(env, request);
        await rejectSubmission(env, decodeURIComponent(rejectMatch[1]));
        return new Response(null, { status: 204 });
      }

      const dismissMatch = path.match(/^\/v1\/moderation\/reports\/([^/]+)\/dismiss$/);
      if (request.method === "POST" && dismissMatch) {
        await requireModerator(env, request);
        await dismissReport(env, decodeURIComponent(dismissMatch[1]));
        return new Response(null, { status: 204 });
      }

      return errorResponse("Not found.", 404);
    } catch (error) {
      console.error("worker_error", error);
      return normalizeError(error);
    }
  },

  async scheduled(controller, env, ctx): Promise<void> {
    console.log("scheduled_moderation_run", { cron: controller.cron, scheduledTime: controller.scheduledTime });
    ctx.waitUntil(runScheduledModeration(env));
  },
} satisfies ExportedHandler<Env>;

async function fetchPublishedReviews(env: Env): Promise<ReviewRecord[]> {
  const result = await env.DB.prepare(`
    SELECT
      id,
      instructor_name AS instructorName,
      squadron_id AS squadronID,
      event_name AS eventName,
      event_kind AS eventKind,
      chill_score AS chillScore,
      grading_score AS gradingScore,
      review_text AS reviewText,
      submitted_at AS submittedAt,
      status,
      submitter_client_id AS submitterClientID,
      updated_at AS updatedAt
    FROM instructor_reviews
    WHERE status = 'approved'
    ORDER BY submitted_at DESC
  `).all<ReviewRecord>();

  return result.results ?? [];
}

async function fetchSubmissionStatuses(env: Env, clientID: string): Promise<SubmissionStatusRecord[]> {
  const result = await env.DB.prepare(`
    SELECT
      id,
      status,
      updated_at AS updatedAt
    FROM review_submissions
    WHERE submitter_client_id = ?
    ORDER BY updated_at DESC
  `).bind(clientID).all<SubmissionStatusRecord>();

  return result.results ?? [];
}

async function fetchReportStatuses(env: Env, clientID: string): Promise<ReportStatusRecord[]> {
  const result = await env.DB.prepare(`
    SELECT
      id,
      status,
      updated_at AS updatedAt
    FROM gouge_reports
    WHERE submitter_client_id = ?
    ORDER BY updated_at DESC
  `).bind(clientID).all<ReportStatusRecord>();

  return result.results ?? [];
}

async function createSubmission(env: Env, payload: ReviewRecord, clientID: string): Promise<{ id: string }> {
  validateReviewPayload(payload);

  const now = nowISO();
  await env.DB.prepare(`
    INSERT OR REPLACE INTO review_submissions (
      id,
      instructor_name,
      squadron_id,
      event_name,
      event_kind,
      chill_score,
      grading_score,
      review_text,
      submitted_at,
      status,
      moderation_state,
      moderation_summary,
      submitter_client_id,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'queued', NULL, ?, ?, ?)
  `).bind(
    payload.id,
    sanitizeText(payload.instructorName),
    sanitizeText(payload.squadronID),
    sanitizeNullableText(payload.eventName),
    payload.eventKind,
    payload.chillScore,
    payload.gradingScore,
    sanitizeText(payload.reviewText),
    payload.submittedAt || now,
    clientID,
    now,
    now,
  ).run();

  return { id: payload.id };
}

async function createReport(env: Env, payload: ReportRecord, clientID: string): Promise<{ id: string }> {
  validateReportPayload(payload);

  const now = nowISO();
  await env.DB.prepare(`
    INSERT OR REPLACE INTO gouge_reports (
      id,
      target_kind,
      instructor_id,
      review_id,
      instructor_name,
      squadron_id,
      event_name,
      event_kind,
      review_text,
      reason_title,
      note,
      submitted_at,
      status,
      submitter_client_id,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?, ?, ?)
  `).bind(
    payload.id,
    payload.targetKind,
    sanitizeText(payload.instructorID),
    sanitizeNullableText(payload.reviewID),
    sanitizeText(payload.instructorName),
    sanitizeText(payload.squadronID),
    sanitizeNullableText(payload.eventName),
    payload.eventKind,
    sanitizeNullableText(payload.reviewText),
    sanitizeText(payload.reasonTitle),
    sanitizeNullableText(payload.note),
    payload.submittedAt || now,
    clientID,
    now,
    now,
  ).run();

  return { id: payload.id };
}

async function signInModerator(env: Env, email: string, password: string) {
  const normalizedEmail = email.trim().toLowerCase();
  const row = await env.DB.prepare(`
    SELECT email, password_hash AS passwordHash, is_active AS isActive
    FROM moderator_accounts
    WHERE lower(email) = ?
    LIMIT 1
  `).bind(normalizedEmail).first<{ email: string; passwordHash: string; isActive: number }>();

  if (!row || row.isActive !== 1) {
    throw httpError("Moderator sign-in failed.", 401);
  }

  const valid = await verifyPassword(password, row.passwordHash);
  if (!valid) {
    throw httpError("Moderator sign-in failed.", 401);
  }

  return issueSessionBundle(env, row.email);
}

async function refreshModerator(env: Env, refreshToken: string) {
  const claims = await verifySessionToken(env, refreshToken, "refresh");
  const row = await env.DB.prepare(`
    SELECT email, is_active AS isActive
    FROM moderator_accounts
    WHERE lower(email) = ?
    LIMIT 1
  `).bind(claims.email.toLowerCase()).first<{ email: string; isActive: number }>();

  if (!row || row.isActive !== 1) {
    throw httpError("Moderator session is no longer valid.", 401);
  }

  return issueSessionBundle(env, row.email);
}

async function requireModerator(env: Env, request: Request): Promise<SessionClaims> {
  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw httpError("Moderator sign-in is required.", 401);
  }

  const token = authorization.slice("Bearer ".length).trim();
  const claims = await verifySessionToken(env, token, "access");
  const row = await env.DB.prepare(`
    SELECT is_active AS isActive
    FROM moderator_accounts
    WHERE lower(email) = ?
    LIMIT 1
  `).bind(claims.email.toLowerCase()).first<{ isActive: number }>();

  if (!row || row.isActive !== 1) {
    throw httpError("Moderator sign-in is required.", 401);
  }

  return claims;
}

async function fetchModerationQueue(env: Env) {
  const [pendingReviewsResult, openReportsResult] = await Promise.all([
    env.DB.prepare(`
      SELECT
        id,
        instructor_name AS instructorName,
        squadron_id AS squadronID,
        event_name AS eventName,
        event_kind AS eventKind,
        chill_score AS chillScore,
        grading_score AS gradingScore,
        review_text AS reviewText,
        submitted_at AS submittedAt,
        status,
        submitter_client_id AS submitterClientID,
        updated_at AS updatedAt
      FROM review_submissions
      WHERE status = 'pending'
      ORDER BY
        CASE moderation_state
          WHEN 'needs_human_review' THEN 0
          WHEN 'queued' THEN 1
          WHEN 'screened_clean' THEN 2
          ELSE 3
        END,
        submitted_at DESC
    `).all<ReviewRecord>(),
    env.DB.prepare(`
      SELECT
        id,
        target_kind AS targetKind,
        instructor_id AS instructorID,
        review_id AS reviewID,
        instructor_name AS instructorName,
        squadron_id AS squadronID,
        event_name AS eventName,
        event_kind AS eventKind,
        review_text AS reviewText,
        reason_title AS reasonTitle,
        note,
        submitted_at AS submittedAt,
        status,
        submitter_client_id AS submitterClientID,
        updated_at AS updatedAt
      FROM gouge_reports
      WHERE status = 'open'
      ORDER BY submitted_at DESC
    `).all<ReportRecord>(),
  ]);

  return {
    pendingReviews: pendingReviewsResult.results ?? [],
    openReports: openReportsResult.results ?? [],
  };
}

async function approveSubmission(env: Env, id: string): Promise<void> {
  const submission = await env.DB.prepare(`
    SELECT
      id,
      instructor_name AS instructorName,
      squadron_id AS squadronID,
      event_name AS eventName,
      event_kind AS eventKind,
      chill_score AS chillScore,
      grading_score AS gradingScore,
      review_text AS reviewText,
      submitted_at AS submittedAt,
      status,
      submitter_client_id AS submitterClientID
    FROM review_submissions
    WHERE id = ?
    LIMIT 1
  `).bind(id).first<ReviewRecord>();

  if (!submission) {
    throw httpError("The selected review could not be found.", 404);
  }

  const now = nowISO();
  await env.DB.batch([
    env.DB.prepare(`
      INSERT OR REPLACE INTO instructor_reviews (
        id,
        instructor_name,
        squadron_id,
        event_name,
        event_kind,
        chill_score,
        grading_score,
        review_text,
        submitted_at,
        status,
        submitter_client_id,
        source_submission_id,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'approved', ?, ?, ?, ?)
    `).bind(
      submission.id,
      submission.instructorName,
      submission.squadronID,
      submission.eventName,
      submission.eventKind,
      submission.chillScore,
      submission.gradingScore,
      submission.reviewText,
      submission.submittedAt,
      submission.submitterClientID,
      submission.id,
      now,
      now,
    ),
    env.DB.prepare(`
      UPDATE review_submissions
      SET status = 'approved',
          moderation_state = 'screened_clean',
          updated_at = ?
      WHERE id = ?
    `).bind(now, submission.id),
  ]);
}

async function rejectSubmission(env: Env, id: string): Promise<void> {
  const now = nowISO();
  await env.DB.batch([
    env.DB.prepare(`
      UPDATE review_submissions
      SET status = 'rejected',
          moderation_state = 'auto_rejected',
          updated_at = ?
      WHERE id = ?
    `).bind(now, id),
    env.DB.prepare(`
      DELETE FROM instructor_reviews
      WHERE id = ? OR source_submission_id = ?
    `).bind(id, id),
    env.DB.prepare(`
      UPDATE gouge_reports
      SET status = 'resolved',
          updated_at = ?
      WHERE review_id = ? AND status = 'open'
    `).bind(now, id),
  ]);
}

async function dismissReport(env: Env, id: string): Promise<void> {
  const now = nowISO();
  await env.DB.prepare(`
    UPDATE gouge_reports
    SET status = 'dismissed',
        updated_at = ?
    WHERE id = ?
  `).bind(now, id).run();
}

async function runScheduledModeration(env: Env): Promise<void> {
  const batchSize = Math.max(1, Number(env.AUTO_MODERATION_MAX_BATCH ?? "40"));
  const result = await env.DB.prepare(`
    SELECT
      id,
      review_text AS reviewText,
      instructor_name AS instructorName,
      event_name AS eventName
    FROM review_submissions
    WHERE status = 'pending' AND moderation_state = 'queued'
    ORDER BY submitted_at ASC
    LIMIT ?
  `).bind(batchSize).all<{ id: string; reviewText: string; instructorName: string; eventName: string | null }>();

  for (const submission of result.results ?? []) {
    const decision = await evaluateSubmission(env, submission.reviewText, submission.instructorName, submission.eventName);
    const now = nowISO();

    if (decision.action === "reject") {
      await env.DB.prepare(`
        UPDATE review_submissions
        SET status = 'rejected',
            moderation_state = 'auto_rejected',
            moderation_summary = ?,
            updated_at = ?
        WHERE id = ?
      `).bind(decision.summary, now, submission.id).run();
      continue;
    }

    const nextState: ModerationState = decision.action === "allow" ? "screened_clean" : "needs_human_review";
    await env.DB.prepare(`
      UPDATE review_submissions
      SET moderation_state = ?,
          moderation_summary = ?,
          updated_at = ?
      WHERE id = ?
    `).bind(nextState, decision.summary, now, submission.id).run();
  }
}

async function evaluateSubmission(env: Env, reviewText: string, instructorName: string, eventName: string | null): Promise<ModerationDecision> {
  const trimmed = reviewText.trim();
  const normalized = trimmed.toLowerCase().replace(/\s+/g, " ");

  if (profanityPatterns.some((pattern) => pattern.test(normalized))) {
    return { action: "reject", summary: "Auto-rejected for profanity or abusive language." };
  }

  if (spamPatterns.some((pattern) => pattern.test(trimmed))) {
    return { action: "reject", summary: "Auto-rejected for spam-like or unsafe content." };
  }

  const words = normalized.split(/\s+/).filter(Boolean);
  if (trimmed.length < 45 || words.length < 8) {
    return { action: "review", summary: "Needs human review because the write-up is very short." };
  }

  if (looksLikeLowQuality(trimmed, words)) {
    return { action: "review", summary: "Needs human review because the write-up looks low effort or repetitive." };
  }

  if (env.ENABLE_AI_MODERATION === "true" && env.AI) {
    const aiDecision = await evaluateWithAI(env, reviewText, instructorName, eventName);
    if (aiDecision) {
      return aiDecision;
    }
  }

  return { action: "allow", summary: "Scheduled screening did not find abuse, profanity, or obvious low-quality issues." };
}

async function evaluateWithAI(env: Env, reviewText: string, instructorName: string, eventName: string | null): Promise<ModerationDecision | null> {
  try {
    const response = await env.AI?.run(env.AI_MODERATION_MODEL ?? "@cf/meta/llama-3.1-8b-instruct", {
      prompt: [
        "You are moderating an instructor review submission.",
        "Return strict JSON with keys action and summary.",
        "Allowed action values: allow, review, reject.",
        "Reject only for obvious profanity, slurs, threats, harassment, or spam.",
        "Use review for weak quality, suspicious claims, personal info, or content that needs a human.",
        "Use allow when it looks clean and useful.",
        `Instructor: ${instructorName}`,
        `Event: ${eventName ?? "Unknown"}`,
        `Review: ${reviewText}`,
      ].join("\n"),
      max_tokens: 200,
    });

    const text = extractAIText(response);
    if (!text) return null;

    const parsed = JSON.parse(text) as Partial<ModerationDecision>;
    if (
      parsed.action === "allow" ||
      parsed.action === "review" ||
      parsed.action === "reject"
    ) {
      return {
        action: parsed.action,
        summary: sanitizeText(parsed.summary ?? "Workers AI moderation pass."),
      };
    }
  } catch (error) {
    console.warn("ai_moderation_failed", error);
  }

  return null;
}

function looksLikeLowQuality(text: string, words: string[]): boolean {
  const uniqueWords = new Set(words);
  const uppercaseRatio = text.replace(/[^A-Z]/g, "").length / Math.max(1, text.replace(/[^A-Za-z]/g, "").length);
  return uniqueWords.size <= Math.max(4, Math.floor(words.length * 0.35)) || uppercaseRatio > 0.72;
}

function extractAIText(response: unknown): string | null {
  if (!response) return null;
  if (typeof response === "string") return response;
  if (typeof response === "object") {
    const maybe = response as { response?: string; result?: { response?: string } };
    return maybe.response ?? maybe.result?.response ?? null;
  }
  return null;
}

function validateReviewPayload(payload: ReviewRecord) {
  if (!payload.id || !payload.instructorName || !payload.squadronID || !payload.reviewText) {
    throw httpError("Incomplete review submission.", 400);
  }
  if (payload.eventKind !== "sim" && payload.eventKind !== "flight") {
    throw httpError("Invalid review type.", 400);
  }
  if (payload.chillScore < 1 || payload.chillScore > 7 || payload.gradingScore < 1 || payload.gradingScore > 7) {
    throw httpError("Scores must stay within the 1 to 7 instructor scale.", 400);
  }
}

function validateReportPayload(payload: ReportRecord) {
  if (!payload.id || !payload.instructorID || !payload.instructorName || !payload.squadronID || !payload.reasonTitle) {
    throw httpError("Incomplete report submission.", 400);
  }
  if (payload.targetKind !== "instructor" && payload.targetKind !== "review") {
    throw httpError("Invalid report target.", 400);
  }
}

function requireSubmitterClientID(request: Request): string {
  const clientID = request.headers.get("x-submitter-client-id")?.trim();
  if (!clientID) {
    throw httpError("Missing submitter client identifier.", 400);
  }
  return clientID;
}

function sanitizeText(value: string): string {
  return value.trim().replace(/\s+/g, " ");
}

function sanitizeNullableText(value: string | null | undefined): string | null {
  if (value == null) return null;
  const normalized = sanitizeText(value);
  return normalized.length === 0 ? null : normalized;
}

function nowISO(): string {
  return new Date().toISOString();
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: jsonHeaders,
  });
}

function errorResponse(message: string, status = 400): Response {
  return new Response(message, { status, headers: jsonHeaders });
}

function httpError(message: string, status: number): Error & { status: number } {
  const error = new Error(message) as Error & { status: number };
  error.status = status;
  return error;
}

function normalizeError(error: unknown): Response {
  if (error instanceof Error && "status" in error && typeof (error as { status: unknown }).status === "number") {
    return errorResponse(error.message, (error as { status: number }).status);
  }
  if (error instanceof Error) {
    return errorResponse(error.message, 500);
  }
  return errorResponse("Unexpected worker error.", 500);
}

async function issueSessionBundle(env: Env, email: string) {
  const accessTTL = Number(env.ACCESS_TOKEN_TTL_SECONDS ?? "43200");
  const refreshTTL = Number(env.REFRESH_TOKEN_TTL_SECONDS ?? "2592000");
  const accessToken = await signSessionToken(env, { email, type: "access", exp: futureEpochSeconds(accessTTL) });
  const refreshToken = await signSessionToken(env, { email, type: "refresh", exp: futureEpochSeconds(refreshTTL) });

  return {
    email,
    accessToken,
    refreshToken,
    expiresAt: new Date(Date.now() + accessTTL * 1000).toISOString(),
  };
}

function futureEpochSeconds(ttlSeconds: number): number {
  return Math.floor(Date.now() / 1000) + ttlSeconds;
}

async function signSessionToken(env: Env, claims: SessionClaims): Promise<string> {
  const payload = encodeBase64Url(JSON.stringify(claims));
  const signature = await signHmac(env.MODERATOR_SESSION_SECRET, payload);
  return `${payload}.${signature}`;
}

async function verifySessionToken(env: Env, token: string, expectedType: SessionClaims["type"]): Promise<SessionClaims> {
  const [payload, signature] = token.split(".");
  if (!payload || !signature) {
    throw httpError("Invalid moderator session.", 401);
  }

  const expectedSignature = await signHmac(env.MODERATOR_SESSION_SECRET, payload);
  if (!timingSafeEqual(signature, expectedSignature)) {
    throw httpError("Invalid moderator session.", 401);
  }

  const claims = JSON.parse(decodeBase64Url(payload)) as SessionClaims;
  if (claims.type !== expectedType || claims.exp <= Math.floor(Date.now() / 1000)) {
    throw httpError("Moderator session expired.", 401);
  }

  return claims;
}

async function signHmac(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  return encodeBase64Url(new Uint8Array(signature));
}

async function verifyPassword(password: string, encodedHash: string): Promise<boolean> {
  const [scheme, iterationsRaw, saltRaw, expectedRaw] = encodedHash.split("$");
  if (scheme !== "pbkdf2" || !iterationsRaw || !saltRaw || !expectedRaw) {
    return false;
  }

  const iterations = Number(iterationsRaw);
  const salt = decodeBase64UrlToBytes(saltRaw);
  const expected = decodeBase64UrlToBytes(expectedRaw);

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"],
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      hash: "SHA-256",
      salt,
      iterations,
    },
    key,
    expected.byteLength * 8,
  );

  return timingSafeEqualBytes(new Uint8Array(bits), expected);
}

function timingSafeEqual(a: string, b: string): boolean {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  return timingSafeEqualBytes(left, right);
}

function timingSafeEqualBytes(a: Uint8Array, b: Uint8Array): boolean {
  if (a.byteLength !== b.byteLength) return false;
  let diff = 0;
  for (let index = 0; index < a.byteLength; index += 1) {
    diff |= a[index] ^ b[index];
  }
  return diff === 0;
}

function encodeBase64Url(value: string | Uint8Array): string {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function decodeBase64Url(value: string): string {
  const binary = atob(value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "="));
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function decodeBase64UrlToBytes(value: string): Uint8Array {
  const binary = atob(value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "="));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}
