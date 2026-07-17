export interface Env {
  DB: D1Database;
  AI?: {
    run: (model: string, input: Record<string, unknown>) => Promise<unknown>;
  };
  MODERATOR_SESSION_SECRET: string;
  AUTH_SESSION_SECRET: string;
  AUTH_APPLE_CLIENT_ID?: string;
  APPLE_TEAM_ID?: string;
  APPLE_KEY_ID?: string;
  APPLE_PRIVATE_KEY?: string;
  RESEND_API_KEY?: string;
  AUTH_EMAIL_FROM?: string;
  SUPABASE_URL?: string;
  SUPABASE_PUBLISHABLE_KEY?: string;
  ACCESS_TOKEN_TTL_SECONDS?: string;
  REFRESH_TOKEN_TTL_SECONDS?: string;
  EMAIL_CODE_TTL_SECONDS?: string;
  PASSWORD_HASH_ITERATIONS?: string;
  AUTO_MODERATION_MAX_BATCH?: string;
  ENABLE_AI_MODERATION?: string;
  AI_MODERATION_MODEL?: string;
}

type ReviewStatus = "pending" | "approved" | "rejected";
type EventKind = "sim" | "flight";
type ReviewActionType = "create" | "edit" | "delete";
type OwnedReviewStatus = "pending_create" | "approved" | "pending_edit" | "pending_delete" | "rejected_create" | "rejected_edit" | "rejected_delete" | "removed";
type ReportStatus = "open" | "dismissed" | "resolved";
type ReportTargetKind = "instructor" | "review";
type CommunitySubmissionCategory = "feedback" | "feature_request" | "support" | "incorrect_gouge";
type CommunityTargetKind = "brief" | "flashcardSet" | "event" | "instructorReview" | "generalLibrary" | "other";
type CommunitySubmissionStatus = "open" | "dismissed" | "resolved";
type ModerationState = "queued" | "screened_clean" | "needs_human_review" | "auto_rejected";
type ModeratorAction = "allow" | "review" | "reject";
type SyllabusID = "delta" | "echo" | "not_sure";
type AccountPermission = "instructor_gouge_moderator";
type AuthMethod = "apple" | "email_password";
type EmailCodePurpose = "verify_email" | "reset_password";

const DEFAULT_PASSWORD_HASH_ITERATIONS = 200_000;
const MIN_PASSWORD_HASH_ITERATIONS = 100_000;
const MAX_PASSWORD_HASH_ITERATIONS = 200_000;

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
  submitterUserID: string | null;
  updatedAt: string;
  actionType?: ReviewActionType | null;
  targetReviewID?: string | null;
  visibilityState?: "public" | "deleted" | null;
};

type OwnedReviewRecord = {
  id: string;
  publicReviewID: string | null;
  submissionID: string | null;
  instructorName: string;
  squadronID: string;
  eventName: string | null;
  eventKind: EventKind;
  chillScore: number;
  gradingScore: number;
  reviewText: string;
  submittedAt: string;
  updatedAt: string;
  status: OwnedReviewStatus;
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
  submitterUserID: string | null;
  updatedAt: string;
};

type CommunitySubmissionRecord = {
  id: string;
  category: CommunitySubmissionCategory;
  summary: string;
  message: string;
  contactEmail: string | null;
  targetKind: CommunityTargetKind | null;
  targetID: string | null;
  targetTitle: string | null;
  targetContext: string | null;
  appVersion: string;
  buildNumber: string | null;
  platform: string;
  submittedAt: string;
  status: CommunitySubmissionStatus;
  submitterClientID: string | null;
  submitterUserID: string | null;
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

type CommunitySubmissionStatusRecord = {
  id: string;
  status: CommunitySubmissionStatus;
  updatedAt: string;
};

type SessionClaims = {
  email: string;
  type: "access" | "refresh";
  exp: number;
};

type AppSessionClaims = {
  sub: string;
  sid: string;
  type: "app_access";
  exp: number;
  authTime: number;
};

type AuthenticatedUser = {
  id: string;
  source: "cloudflare" | "supabase";
  sessionID?: string;
  authTime: number;
  accessToken?: string;
};

type UserRow = {
  id: string;
  displayName: string | null;
  email: string | null;
  emailVerified: number;
  passwordHash: string | null;
  appleSubject: string | null;
  appleEmail: string | null;
  squadronID: string | null;
  syllabusID: SyllabusID | null;
  deletedAt: string | null;
  createdAt: string;
  updatedAt: string;
};

type UserProfile = {
  id: string;
  displayName: string | null;
  email: string | null;
  emailVerified: boolean;
  authMethods: AuthMethod[];
  squadronID: string | null;
  syllabusID: SyllabusID | null;
  permissions: AccountPermission[];
  profileComplete: boolean;
};

type AppSessionBundle = {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  profile: UserProfile;
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

      if (request.method === "POST" && path === "/v1/auth/apple") {
        const payload = (await request.json()) as {
          identityToken?: string;
          authorizationCode?: string;
          displayName?: string;
          email?: string;
          nonce?: string;
        };
        return json(await signInWithApple(env, request, payload));
      }

      if (request.method === "POST" && path === "/v1/auth/email/register") {
        const payload = (await request.json()) as { email?: string; password?: string; displayName?: string };
        await registerWithEmail(env, request, payload);
        return json({ ok: true, verificationRequired: true }, 201);
      }

      if (request.method === "POST" && path === "/v1/auth/email/verify") {
        const payload = (await request.json()) as { email?: string; code?: string };
        return json(await verifyEmailCodeAndSignIn(env, request, payload));
      }

      if (request.method === "POST" && path === "/v1/auth/email/sign-in") {
        const payload = (await request.json()) as { email?: string; password?: string };
        return json(await signInWithEmail(env, request, payload));
      }

      if (request.method === "POST" && path === "/v1/auth/email/password-reset/request") {
        const payload = (await request.json()) as { email?: string };
        await requestPasswordReset(env, request, payload);
        return json({ ok: true });
      }

      if (request.method === "POST" && path === "/v1/auth/email/password-reset/confirm") {
        const payload = (await request.json()) as { email?: string; code?: string; newPassword?: string };
        return json(await confirmPasswordReset(env, request, payload));
      }

      if (request.method === "POST" && path === "/v1/auth/refresh") {
        const payload = (await request.json()) as { refreshToken?: string };
        return json(await refreshAppSession(env, request, payload.refreshToken ?? ""));
      }

      if (request.method === "POST" && path === "/v1/auth/sign-out") {
        await signOutAppSession(env, request);
        return new Response(null, { status: 204 });
      }

      if (request.method === "GET" && path === "/v1/me") {
        const user = await requireAuthenticatedUser(env, request);
        return json({ profile: await fetchUserProfile(env, user.id) });
      }

      if (request.method === "PATCH" && path === "/v1/me") {
        const user = await requireAuthenticatedUser(env, request);
        const payload = (await request.json()) as { displayName?: string | null; squadronID?: string | null; syllabusID?: SyllabusID | null };
        return json({ profile: await updateUserProfile(env, user.id, payload) });
      }

      if (request.method === "DELETE" && path === "/v1/me") {
        const user = await requireAuthenticatedUser(env, request);
        const payload = await optionalJSON<{ appleAuthorizationCode?: string }>(request);
        await requireRecentAuthentication(user);
        await deleteAccount(env, user.id, payload?.appleAuthorizationCode);
        return new Response(null, { status: 204 });
      }

      if (request.method === "GET" && path === "/v1/reviews/published") {
        return json({ reviews: await fetchPublishedReviews(env) });
      }

      if (request.method === "GET" && path === "/v1/me/reviews") {
        const user = await requireAuthenticatedUser(env, request);
        return json({ reviews: await fetchOwnedReviews(env, user.id) });
      }

      if (request.method === "GET" && path === "/v1/submissions/statuses") {
        const user = await optionalAuthenticatedUser(env, request);
        const clientID = user ? optionalSubmitterClientID(request) : requireSubmitterClientID(request);
        return json({ statuses: await fetchSubmissionStatuses(env, clientID, user?.id ?? null) });
      }

      if (request.method === "GET" && path === "/v1/reports/statuses") {
        const user = await optionalAuthenticatedUser(env, request);
        const clientID = user ? optionalSubmitterClientID(request) : requireSubmitterClientID(request);
        return json({ statuses: await fetchReportStatuses(env, clientID, user?.id ?? null) });
      }

      if (request.method === "GET" && path === "/v1/community/submissions/statuses") {
        const user = await optionalAuthenticatedUser(env, request);
        const clientID = user ? optionalSubmitterClientID(request) : requireSubmitterClientID(request);
        return json({ statuses: await fetchCommunitySubmissionStatuses(env, clientID, user?.id ?? null) });
      }

      if (request.method === "POST" && path === "/v1/submissions") {
        const user = await optionalAuthenticatedUser(env, request);
        const clientID = user ? optionalSubmitterClientID(request) : requireSubmitterClientID(request);
        const payload = (await request.json()) as ReviewRecord;
        const created = await createSubmission(env, payload, clientID, user?.id ?? null);
        return json({ id: created.id }, 201);
      }

      const editOwnedReviewMatch = path.match(/^\/v1\/me\/reviews\/([^/]+)\/edit$/);
      if (request.method === "POST" && editOwnedReviewMatch) {
        const user = await requireAuthenticatedUser(env, request);
        const payload = (await request.json()) as ReviewRecord;
        await submitReviewEdit(env, user.id, decodeURIComponent(editOwnedReviewMatch[1]), payload);
        return new Response(null, { status: 204 });
      }

      const deleteOwnedReviewMatch = path.match(/^\/v1\/me\/reviews\/([^/]+)\/delete$/);
      if (request.method === "POST" && deleteOwnedReviewMatch) {
        const user = await requireAuthenticatedUser(env, request);
        await requestReviewDeletion(env, user.id, decodeURIComponent(deleteOwnedReviewMatch[1]));
        return new Response(null, { status: 204 });
      }

      if (request.method === "POST" && path === "/v1/reports") {
        const user = await optionalAuthenticatedUser(env, request);
        const clientID = user ? optionalSubmitterClientID(request) : requireSubmitterClientID(request);
        const payload = (await request.json()) as ReportRecord;
        const created = await createReport(env, payload, clientID, user?.id ?? null);
        return json({ id: created.id }, 201);
      }

      if (request.method === "POST" && path === "/v1/community/submissions") {
        const user = await optionalAuthenticatedUser(env, request);
        const clientID = user ? optionalSubmitterClientID(request) : requireSubmitterClientID(request);
        const payload = (await request.json()) as CommunitySubmissionRecord;
        const created = await createCommunitySubmission(env, payload, clientID, user?.id ?? null);
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
        await requireModeratorOrPermission(env, request);
        return json(await fetchModerationQueue(env));
      }

      const approveMatch = path.match(/^\/v1\/moderation\/submissions\/([^/]+)\/approve$/);
      if (request.method === "POST" && approveMatch) {
        await requireModeratorOrPermission(env, request);
        await approveSubmission(env, decodeURIComponent(approveMatch[1]));
        return new Response(null, { status: 204 });
      }

      const rejectMatch = path.match(/^\/v1\/moderation\/submissions\/([^/]+)\/reject$/);
      if (request.method === "POST" && rejectMatch) {
        await requireModeratorOrPermission(env, request);
        await rejectSubmission(env, decodeURIComponent(rejectMatch[1]));
        return new Response(null, { status: 204 });
      }

      const dismissMatch = path.match(/^\/v1\/moderation\/reports\/([^/]+)\/dismiss$/);
      if (request.method === "POST" && dismissMatch) {
        await requireModeratorOrPermission(env, request);
        await dismissReport(env, decodeURIComponent(dismissMatch[1]));
        return new Response(null, { status: 204 });
      }

      const resolveCommunityMatch = path.match(/^\/v1\/moderation\/community-submissions\/([^/]+)\/resolve$/);
      if (request.method === "POST" && resolveCommunityMatch) {
        await requireModeratorOrPermission(env, request);
        await resolveCommunitySubmission(env, decodeURIComponent(resolveCommunityMatch[1]));
        return new Response(null, { status: 204 });
      }

      const dismissCommunityMatch = path.match(/^\/v1\/moderation\/community-submissions\/([^/]+)\/dismiss$/);
      if (request.method === "POST" && dismissCommunityMatch) {
        await requireModeratorOrPermission(env, request);
        await dismissCommunitySubmission(env, decodeURIComponent(dismissCommunityMatch[1]));
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
      submitter_user_id AS submitterUserID,
      updated_at AS updatedAt,
      'create' AS actionType,
      NULL AS targetReviewID,
      'public' AS visibilityState
    FROM instructor_reviews
    WHERE status = 'approved'
    ORDER BY submitted_at DESC
  `).all<ReviewRecord>();

  return result.results ?? [];
}

async function fetchSubmissionStatuses(env: Env, clientID: string | null, userID: string | null): Promise<SubmissionStatusRecord[]> {
  if (userID) {
    const result = await env.DB.prepare(`
      SELECT
        id,
        status,
        updated_at AS updatedAt
      FROM review_submissions
      WHERE submitter_user_id = ?
      ORDER BY updated_at DESC
    `).bind(userID).all<SubmissionStatusRecord>();

    return result.results ?? [];
  }

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

async function fetchReportStatuses(env: Env, clientID: string | null, userID: string | null): Promise<ReportStatusRecord[]> {
  if (userID) {
    const result = await env.DB.prepare(`
      SELECT
        id,
        status,
        updated_at AS updatedAt
      FROM gouge_reports
      WHERE submitter_user_id = ?
      ORDER BY updated_at DESC
    `).bind(userID).all<ReportStatusRecord>();

    return result.results ?? [];
  }

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

async function fetchCommunitySubmissionStatuses(env: Env, clientID: string | null, userID: string | null): Promise<CommunitySubmissionStatusRecord[]> {
  if (userID) {
    const result = await env.DB.prepare(`
      SELECT
        id,
        status,
        updated_at AS updatedAt
      FROM community_submissions
      WHERE submitter_user_id = ?
      ORDER BY updated_at DESC
    `).bind(userID).all<CommunitySubmissionStatusRecord>();

    return result.results ?? [];
  }

  const result = await env.DB.prepare(`
    SELECT
      id,
      status,
      updated_at AS updatedAt
    FROM community_submissions
    WHERE submitter_client_id = ?
    ORDER BY updated_at DESC
  `).bind(clientID).all<CommunitySubmissionStatusRecord>();

  return result.results ?? [];
}

async function createSubmission(env: Env, payload: ReviewRecord, clientID: string | null, userID: string | null): Promise<{ id: string }> {
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
      submitter_user_id,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'queued', NULL, ?, ?, ?, ?)
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
    userID,
    now,
    now,
  ).run();

  return { id: payload.id };
}

async function createReport(env: Env, payload: ReportRecord, clientID: string | null, userID: string | null): Promise<{ id: string }> {
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
      submitter_user_id,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?, ?, ?, ?)
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
    userID,
    now,
    now,
  ).run();

  return { id: payload.id };
}

async function createCommunitySubmission(env: Env, payload: CommunitySubmissionRecord, clientID: string | null, userID: string | null): Promise<{ id: string }> {
  validateCommunitySubmissionPayload(payload);

  const now = nowISO();
  await env.DB.prepare(`
    INSERT OR REPLACE INTO community_submissions (
      id,
      category,
      summary,
      message,
      contact_email,
      target_kind,
      target_id,
      target_title,
      target_context,
      app_version,
      build_number,
      platform,
      submitted_at,
      status,
      submitter_client_id,
      submitter_user_id,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?, ?, ?, ?)
  `).bind(
    payload.id,
    payload.category,
    sanitizeText(payload.summary),
    sanitizeText(payload.message),
    sanitizeNullableText(payload.contactEmail),
    payload.targetKind,
    sanitizeNullableText(payload.targetID),
    sanitizeNullableText(payload.targetTitle),
    sanitizeNullableText(payload.targetContext),
    sanitizeText(payload.appVersion),
    sanitizeNullableText(payload.buildNumber),
    sanitizeText(payload.platform),
    payload.submittedAt || now,
    clientID,
    userID,
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

async function signInWithApple(
  env: Env,
  request: Request,
  payload: { identityToken?: string; authorizationCode?: string; displayName?: string; email?: string; nonce?: string },
): Promise<AppSessionBundle> {
  await enforceAuthRateLimit(env, request, "apple_sign_in", 12);
  const appleClaims = await verifyAppleIdentityToken(env, payload.identityToken ?? "", payload.nonce);
  const normalizedEmail = normalizeEmail(payload.email ?? appleClaims.email);
  const displayName = sanitizeNullableText(payload.displayName);
  const now = nowISO();

  let user = await env.DB.prepare(`
    SELECT
      id,
      display_name AS displayName,
      email,
      email_verified AS emailVerified,
      password_hash AS passwordHash,
      apple_subject AS appleSubject,
      apple_email AS appleEmail,
      squadron_id AS squadronID,
      syllabus_id AS syllabusID,
      deleted_at AS deletedAt,
      created_at AS createdAt,
      updated_at AS updatedAt
    FROM users
    WHERE apple_subject = ? AND deleted_at IS NULL
    LIMIT 1
  `).bind(appleClaims.sub).first<UserRow>();

  if (!user && normalizedEmail) {
    user = await env.DB.prepare(`
      SELECT
        id,
        display_name AS displayName,
        email,
        email_verified AS emailVerified,
        password_hash AS passwordHash,
        apple_subject AS appleSubject,
        apple_email AS appleEmail,
        squadron_id AS squadronID,
        syllabus_id AS syllabusID,
        deleted_at AS deletedAt,
        created_at AS createdAt,
        updated_at AS updatedAt
      FROM users
      WHERE lower(email) = ? AND deleted_at IS NULL
      LIMIT 1
    `).bind(normalizedEmail).first<UserRow>();
  }

  if (!user) {
    const userID = crypto.randomUUID();
    await env.DB.prepare(`
      INSERT INTO users (
        id,
        display_name,
        email,
        email_verified,
        apple_subject,
        apple_email,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userID,
      displayName,
      normalizedEmail,
      appleClaims.emailVerified ? 1 : 0,
      appleClaims.sub,
      normalizedEmail,
      now,
      now,
    ).run();
    await linkLegacySubmissions(env, userID, null);
    return issueAppSessionBundle(env, request, userID);
  }

  await env.DB.prepare(`
    UPDATE users
    SET apple_subject = ?,
        apple_email = coalesce(?, apple_email),
        email = coalesce(email, ?),
        email_verified = CASE WHEN ? IS NOT NULL THEN 1 ELSE email_verified END,
        display_name = coalesce(display_name, ?),
        updated_at = ?
    WHERE id = ?
  `).bind(
    appleClaims.sub,
    normalizedEmail,
    normalizedEmail,
    normalizedEmail,
    displayName,
    now,
    user.id,
  ).run();

  await linkLegacySubmissions(env, user.id, normalizedEmail);
  return issueAppSessionBundle(env, request, user.id);
}

async function registerWithEmail(
  env: Env,
  request: Request,
  payload: { email?: string; password?: string; displayName?: string },
): Promise<void> {
  await enforceAuthRateLimit(env, request, "email_register", 6);
  const email = requireEmail(payload.email);
  const password = requireStrongPassword(payload.password ?? "");
  const displayName = sanitizeNullableText(payload.displayName);
  const now = nowISO();
  const passwordHash = await createPasswordHash(env, password);

  const existing = await userByEmail(env, email);
  let userID = existing?.id ?? crypto.randomUUID();

  if (existing?.deletedAt) {
    throw httpError("Unable to create account with that email.", 400);
  }

  if (existing) {
    await env.DB.prepare(`
      UPDATE users
      SET password_hash = ?,
          display_name = coalesce(display_name, ?),
          updated_at = ?
      WHERE id = ?
    `).bind(passwordHash, displayName, now, existing.id).run();
    userID = existing.id;
  } else {
    await env.DB.prepare(`
      INSERT INTO users (
        id,
        display_name,
        email,
        email_verified,
        password_hash,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, 0, ?, ?, ?)
    `).bind(userID, displayName, email, passwordHash, now, now).run();
  }

  await linkLegacySubmissions(env, userID, email);
  await createAndSendEmailCode(env, userID, email, "verify_email");
}

async function verifyEmailCodeAndSignIn(
  env: Env,
  request: Request,
  payload: { email?: string; code?: string },
): Promise<AppSessionBundle> {
  await enforceAuthRateLimit(env, request, "email_verify", 10);
  const email = requireEmail(payload.email);
  const user = await userByEmail(env, email);
  if (!user || user.deletedAt) {
    throw genericAuthError();
  }
  await consumeEmailCode(env, user.id, email, "verify_email", payload.code ?? "");
  await env.DB.prepare(`
    UPDATE users
    SET email_verified = 1,
        updated_at = ?
    WHERE id = ?
  `).bind(nowISO(), user.id).run();
  await linkLegacySubmissions(env, user.id, email);
  return issueAppSessionBundle(env, request, user.id);
}

async function signInWithEmail(
  env: Env,
  request: Request,
  payload: { email?: string; password?: string },
): Promise<AppSessionBundle> {
  await enforceAuthRateLimit(env, request, "email_sign_in", 8);
  const email = requireEmail(payload.email);
  const user = await userByEmail(env, email);
  if (!user || user.deletedAt || !user.passwordHash) {
    throw genericAuthError();
  }
  const valid = await verifyPassword(payload.password ?? "", user.passwordHash);
  if (!valid) {
    throw genericAuthError();
  }
  if (user.emailVerified !== 1) {
    await createAndSendEmailCode(env, user.id, email, "verify_email");
    throw httpError("Email verification is required before signing in.", 403);
  }
  await linkLegacySubmissions(env, user.id, email);
  return issueAppSessionBundle(env, request, user.id);
}

async function requestPasswordReset(env: Env, request: Request, payload: { email?: string }): Promise<void> {
  await enforceAuthRateLimit(env, request, "password_reset_request", 5);
  const email = normalizeEmail(payload.email);
  if (!email) {
    return;
  }
  const user = await userByEmail(env, email);
  if (!user || user.deletedAt) {
    return;
  }
  await createAndSendEmailCode(env, user.id, email, "reset_password");
}

async function confirmPasswordReset(
  env: Env,
  request: Request,
  payload: { email?: string; code?: string; newPassword?: string },
): Promise<AppSessionBundle> {
  await enforceAuthRateLimit(env, request, "password_reset_confirm", 8);
  const email = requireEmail(payload.email);
  const password = requireStrongPassword(payload.newPassword ?? "");
  const user = await userByEmail(env, email);
  if (!user || user.deletedAt) {
    throw genericAuthError();
  }
  await consumeEmailCode(env, user.id, email, "reset_password", payload.code ?? "");
  const passwordHash = await createPasswordHash(env, password);
  await env.DB.prepare(`
    UPDATE users
    SET password_hash = ?,
        email_verified = 1,
        updated_at = ?
    WHERE id = ?
  `).bind(passwordHash, nowISO(), user.id).run();
  return issueAppSessionBundle(env, request, user.id);
}

async function refreshAppSession(env: Env, request: Request, refreshToken: string): Promise<AppSessionBundle> {
  if (!refreshToken) {
    throw httpError("Session refresh is required.", 401);
  }
  const tokenHash = await hashOpaqueToken(env, refreshToken);
  const row = await env.DB.prepare(`
    SELECT
      s.id AS id,
      s.user_id AS userID,
      s.expires_at AS expiresAt,
      u.deleted_at AS deletedAt
    FROM user_sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.refresh_token_hash = ?
      AND s.revoked_at IS NULL
    LIMIT 1
  `).bind(tokenHash).first<{ id: string; userID: string; expiresAt: string; deletedAt: string | null }>();

  if (!row || row.deletedAt || Date.parse(row.expiresAt) <= Date.now()) {
    throw httpError("Session has expired.", 401);
  }

  await env.DB.prepare(`
    UPDATE user_sessions
    SET revoked_at = ?,
        last_seen_at = ?
    WHERE id = ?
  `).bind(nowISO(), nowISO(), row.id).run();

  return issueAppSessionBundle(env, request, row.userID);
}

async function signOutAppSession(env: Env, request: Request): Promise<void> {
  const user = await optionalAuthenticatedUser(env, request);
  if (!user || user.source !== "cloudflare" || !user.sessionID) return;
  const now = nowISO();
  await env.DB.prepare(`
    UPDATE user_sessions
    SET revoked_at = ?,
        last_seen_at = ?
    WHERE id = ?
  `).bind(now, now, user.sessionID).run();
}

async function requireModeratorOrPermission(env: Env, request: Request): Promise<void> {
  const appUser = await optionalAuthenticatedUser(env, request);
  if (appUser) {
    await requirePermission(env, appUser, "instructor_gouge_moderator");
    return;
  }
  await requireModerator(env, request);
}

async function optionalAuthenticatedUser(env: Env, request: Request): Promise<AuthenticatedUser | null> {
  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return null;
  }
  try {
    return await requireAuthenticatedUser(env, request);
  } catch {
    return null;
  }
}

async function requireAuthenticatedUser(env: Env, request: Request): Promise<AuthenticatedUser> {
  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw httpError("Sign-in is required.", 401);
  }
  const token = authorization.slice("Bearer ".length).trim();

  try {
    return await authenticatedCloudflareUser(env, token);
  } catch {
    // Supabase JWTs are now the primary app session; the legacy Cloudflare
    // app-session verifier remains here only for migration compatibility.
  }

  return authenticatedSupabaseUser(env, token);
}

async function authenticatedCloudflareUser(env: Env, token: string): Promise<AuthenticatedUser> {
  const claims = await verifyAppAccessToken(env, token);
  const row = await env.DB.prepare(`
    SELECT
      s.revoked_at AS revokedAt,
      s.expires_at AS refreshExpiresAt,
      u.deleted_at AS deletedAt
    FROM user_sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.id = ? AND s.user_id = ?
    LIMIT 1
  `).bind(claims.sid, claims.sub).first<{ revokedAt: string | null; refreshExpiresAt: string; deletedAt: string | null }>();

  if (!row || row.revokedAt || row.deletedAt || Date.parse(row.refreshExpiresAt) <= Date.now()) {
    throw httpError("Sign-in is required.", 401);
  }

  return {
    id: claims.sub,
    source: "cloudflare",
    sessionID: claims.sid,
    authTime: claims.authTime,
  };
}

async function authenticatedSupabaseUser(env: Env, token: string): Promise<AuthenticatedUser> {
  const baseURL = normalizedSupabaseURL(env);
  const response = await fetch(`${baseURL}/auth/v1/user`, {
    headers: {
      accept: "application/json",
      apikey: requiredSupabasePublishableKey(env),
      authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw httpError("Sign-in is required.", 401);
  }

  const user = await response.json() as { id?: string };
  if (!user.id) {
    throw httpError("Sign-in is required.", 401);
  }

  return {
    id: user.id,
    source: "supabase",
    authTime: Math.floor(Date.now() / 1000),
    accessToken: token,
  };
}

async function requirePermission(env: Env, user: AuthenticatedUser, permission: AccountPermission): Promise<void> {
  if (user.source === "supabase") {
    await requireSupabasePermission(env, user, permission);
    return;
  }

  const row = await env.DB.prepare(`
    SELECT role
    FROM user_roles
    WHERE user_id = ? AND role = ?
    LIMIT 1
  `).bind(user.id, permission).first<{ role: string }>();
  if (!row) {
    throw httpError("Moderator permission is required.", 403);
  }
}

async function requireSupabasePermission(env: Env, user: AuthenticatedUser, permission: AccountPermission): Promise<void> {
  if (!user.accessToken) {
    throw httpError("Moderator permission is required.", 403);
  }

  const baseURL = normalizedSupabaseURL(env);
  const params = new URLSearchParams({
    user_id: `eq.${user.id}`,
    permission: `eq.${permission}`,
    select: "permission",
    limit: "1",
  });
  const response = await fetch(`${baseURL}/rest/v1/account_roles?${params.toString()}`, {
    headers: {
      accept: "application/json",
      apikey: requiredSupabasePublishableKey(env),
      authorization: `Bearer ${user.accessToken}`,
    },
  });

  if (!response.ok) {
    throw httpError("Moderator permission is required.", response.status === 401 ? 401 : 403);
  }

  const rows = await response.json() as Array<{ permission?: string }>;
  if (!rows.some((row) => row.permission === permission)) {
    throw httpError("Moderator permission is required.", 403);
  }
}

async function fetchUserProfile(env: Env, userID: string): Promise<UserProfile> {
  const user = await userByID(env, userID);
  if (!user || user.deletedAt) {
    throw httpError("Account not found.", 404);
  }
  const roles = await env.DB.prepare(`
    SELECT role
    FROM user_roles
    WHERE user_id = ?
    ORDER BY role
  `).bind(userID).all<{ role: AccountPermission }>();
  const permissions = (roles.results ?? [])
    .map((row) => row.role)
    .filter((role): role is AccountPermission => role === "instructor_gouge_moderator");

  return {
    id: user.id,
    displayName: user.displayName,
    email: user.email,
    emailVerified: user.emailVerified === 1,
    authMethods: [
      user.appleSubject ? "apple" : null,
      user.passwordHash ? "email_password" : null,
    ].filter((method): method is AuthMethod => method != null),
    squadronID: user.squadronID,
    syllabusID: user.syllabusID,
    permissions,
    profileComplete: Boolean(user.squadronID && user.syllabusID),
  };
}

async function updateUserProfile(
  env: Env,
  userID: string,
  payload: { displayName?: string | null; squadronID?: string | null; syllabusID?: SyllabusID | null },
): Promise<UserProfile> {
  const displayName = payload.displayName === undefined ? undefined : sanitizeNullableText(payload.displayName);
  const squadronID = payload.squadronID === undefined ? undefined : normalizedProfileChoice(payload.squadronID);
  const syllabusID = payload.syllabusID === undefined ? undefined : normalizedSyllabusID(payload.syllabusID);
  const now = nowISO();
  const updates: string[] = ["updated_at = ?"];
  const bindings: unknown[] = [now];

  if (displayName !== undefined) {
    updates.push("display_name = ?");
    bindings.push(displayName);
  }
  if (squadronID !== undefined) {
    updates.push("squadron_id = ?");
    bindings.push(squadronID);
  }
  if (syllabusID !== undefined) {
    updates.push("syllabus_id = ?");
    bindings.push(syllabusID);
  }
  bindings.push(userID);

  await env.DB.prepare(`
    UPDATE users
    SET ${updates.join(", ")}
    WHERE id = ? AND deleted_at IS NULL
  `).bind(...bindings).run();

  return fetchUserProfile(env, userID);
}

async function deleteAccount(env: Env, userID: string, appleAuthorizationCode?: string): Promise<void> {
  const user = await userByID(env, userID);

  if (appleAuthorizationCode && user?.appleSubject) {
    await revokeAppleAuthorizationIfConfigured(env, appleAuthorizationCode);
  }

  const now = nowISO();
  await env.DB.batch([
    env.DB.prepare("DELETE FROM instructor_reviews WHERE submitter_user_id = ?").bind(userID),
    env.DB.prepare("DELETE FROM review_submissions WHERE submitter_user_id = ?").bind(userID),
    env.DB.prepare("DELETE FROM gouge_reports WHERE submitter_user_id = ?").bind(userID),
    env.DB.prepare("DELETE FROM community_submissions WHERE submitter_user_id = ?").bind(userID),
    env.DB.prepare("DELETE FROM user_roles WHERE user_id = ?").bind(userID),
    env.DB.prepare("DELETE FROM user_sessions WHERE user_id = ?").bind(userID),
    env.DB.prepare("DELETE FROM auth_email_codes WHERE user_id = ?").bind(userID),
    env.DB.prepare(`
      UPDATE users
      SET deleted_at = ?,
          display_name = NULL,
          email = NULL,
          email_verified = 0,
          password_hash = NULL,
          apple_subject = NULL,
          apple_email = NULL,
          squadron_id = NULL,
          syllabus_id = NULL,
          updated_at = ?
      WHERE id = ?
    `).bind(now, now, userID),
  ]);
}

async function fetchModerationQueue(env: Env) {
  const [pendingReviewsResult, openReportsResult, openCommunitySubmissionsResult] = await Promise.all([
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
        submitter_user_id AS submitterUserID,
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
        submitter_user_id AS submitterUserID,
        updated_at AS updatedAt
      FROM gouge_reports
      WHERE status = 'open'
      ORDER BY submitted_at DESC
    `).all<ReportRecord>(),
    env.DB.prepare(`
      SELECT
        id,
        category,
        summary,
        message,
        contact_email AS contactEmail,
        target_kind AS targetKind,
        target_id AS targetID,
        target_title AS targetTitle,
        target_context AS targetContext,
        app_version AS appVersion,
        build_number AS buildNumber,
        platform,
        submitted_at AS submittedAt,
        status,
        submitter_client_id AS submitterClientID,
        submitter_user_id AS submitterUserID,
        updated_at AS updatedAt
      FROM community_submissions
      WHERE status = 'open'
      ORDER BY submitted_at DESC
    `).all<CommunitySubmissionRecord>(),
  ]);

  return {
    pendingReviews: (pendingReviewsResult.results ?? []).map(decorateReviewRecord),
    openReports: openReportsResult.results ?? [],
    openCommunitySubmissions: openCommunitySubmissionsResult.results ?? [],
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
      submitter_client_id AS submitterClientID,
      submitter_user_id AS submitterUserID,
      updated_at AS updatedAt
    FROM review_submissions
    WHERE id = ?
    LIMIT 1
  `).bind(id).first<ReviewRecord>();

  if (!submission) {
    throw httpError("The selected review could not be found.", 404);
  }

  const now = nowISO();
  const metadata = reviewActionMetadata(submission.id);
  const actionType = metadata.actionType;

  if (actionType === "edit") {
    const targetReview = await requireOwnedReview(env, metadata.targetReviewID ?? "", submission.submitterUserID);
    await env.DB.batch([
      env.DB.prepare(`
        UPDATE instructor_reviews
        SET instructor_name = ?,
            squadron_id = ?,
            event_name = ?,
            event_kind = ?,
            chill_score = ?,
            grading_score = ?,
            review_text = ?,
            updated_at = ?,
            status = 'approved'
        WHERE id = ?
      `).bind(
        submission.instructorName,
        submission.squadronID,
        submission.eventName,
        submission.eventKind,
        submission.chillScore,
        submission.gradingScore,
        submission.reviewText,
        now,
        targetReview.id
      ),
      env.DB.prepare(`
        UPDATE review_submissions
        SET status = 'approved',
            moderation_state = 'screened_clean',
            updated_at = ?
        WHERE id = ?
      `).bind(now, submission.id),
    ]);
    return;
  }

  if (actionType === "delete") {
    const targetReview = await requireOwnedReview(env, metadata.targetReviewID ?? "", submission.submitterUserID);
    await env.DB.batch([
      env.DB.prepare(`
        UPDATE instructor_reviews
        SET status = 'rejected',
            updated_at = ?
        WHERE id = ?
      `).bind(now, targetReview.id),
      env.DB.prepare(`
        UPDATE review_submissions
        SET status = 'approved',
            moderation_state = 'screened_clean',
            updated_at = ?
        WHERE id = ?
      `).bind(now, submission.id),
    ]);
    return;
  }

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
        submitter_user_id,
        source_submission_id,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'approved', ?, ?, ?, ?, ?)
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
      submission.submitterUserID,
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
  const submission = await env.DB.prepare(`
    SELECT
      id,
      submitter_user_id AS submitterUserID
    FROM review_submissions
    WHERE id = ?
    LIMIT 1
  `).bind(id).first<{ id: string; submitterUserID: string | null }>();

  if (!submission) {
    throw httpError("The selected review could not be found.", 404);
  }

  const now = nowISO();
  const metadata = reviewActionMetadata(submission.id);
  const actionType = metadata.actionType;

  if (actionType === "delete") {
    const targetReview = await requireOwnedReview(env, metadata.targetReviewID ?? "", submission.submitterUserID);
    await env.DB.batch([
      env.DB.prepare(`
        UPDATE review_submissions
        SET status = 'rejected',
            moderation_state = 'auto_rejected',
            updated_at = ?
        WHERE id = ?
      `).bind(now, id),
      env.DB.prepare(`
        UPDATE instructor_reviews
        SET status = 'approved',
            updated_at = ?
        WHERE id = ?
      `).bind(now, targetReview.id),
    ]);
    return;
  }

  if (actionType === "edit") {
    await env.DB.prepare(`
      UPDATE review_submissions
      SET status = 'rejected',
          moderation_state = 'auto_rejected',
          updated_at = ?
      WHERE id = ?
    `).bind(now, id).run();
    return;
  }

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

async function fetchOwnedReviews(env: Env, userID: string): Promise<OwnedReviewRecord[]> {
  const [reviewResult, submissionResult] = await Promise.all([
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
        submitter_user_id AS submitterUserID,
        updated_at AS updatedAt
      FROM instructor_reviews
      WHERE submitter_user_id = ?
      ORDER BY updated_at DESC
    `).bind(userID).all<ReviewRecord>(),
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
        submitter_user_id AS submitterUserID,
        updated_at AS updatedAt
      FROM review_submissions
      WHERE submitter_user_id = ?
      ORDER BY updated_at DESC
    `).bind(userID).all<ReviewRecord>(),
  ]);

  const reviews = reviewResult.results ?? [];
  const submissions = submissionResult.results ?? [];

  const latestSubmissionByTarget = new Map<string, ReviewRecord>();
  const ownedReviewIDs = new Set(reviews.map((review) => review.id));
  for (const submission of submissions) {
    const targetReviewID = reviewActionMetadata(submission.id).targetReviewID;
    if (!targetReviewID || latestSubmissionByTarget.has(targetReviewID)) continue;
    latestSubmissionByTarget.set(targetReviewID, submission);
  }

  const ownedReviews: OwnedReviewRecord[] = reviews.map((review) => {
    const latestSubmission = latestSubmissionByTarget.get(review.id);
    const latestAction = latestSubmission ? reviewActionMetadata(latestSubmission.id) : null;
    let status: OwnedReviewStatus = "approved";
    let contentSource: ReviewRecord = review;

    if (review.status === "rejected") {
      status = "removed";
    } else if (latestSubmission?.status === "pending" && latestAction?.actionType === "edit") {
      status = "pending_edit";
      contentSource = latestSubmission;
    } else if (latestSubmission?.status === "pending" && latestAction?.actionType === "delete") {
      status = "pending_delete";
    } else if (latestSubmission?.status === "rejected" && latestAction?.actionType === "edit") {
      status = "rejected_edit";
      contentSource = latestSubmission;
    } else if (latestSubmission?.status === "rejected" && latestAction?.actionType === "delete") {
      status = "rejected_delete";
    }

    return {
      id: review.id,
      publicReviewID: review.id,
      submissionID: latestSubmission?.id ?? null,
      instructorName: contentSource.instructorName,
      squadronID: contentSource.squadronID,
      eventName: contentSource.eventName ?? null,
      eventKind: contentSource.eventKind,
      chillScore: contentSource.chillScore,
      gradingScore: contentSource.gradingScore,
      reviewText: contentSource.reviewText,
      submittedAt: review.submittedAt,
      updatedAt: (latestSubmission?.updatedAt ?? review.updatedAt) ?? review.submittedAt,
      status,
    };
  });

  const pendingCreateSubmissions = submissions
    .filter((submission) => reviewActionMetadata(submission.id).actionType === "create" && !ownedReviewIDs.has(submission.id))
    .map<OwnedReviewRecord>((submission) => ({
      id: submission.id,
      publicReviewID: null,
      submissionID: submission.id,
      instructorName: submission.instructorName,
      squadronID: submission.squadronID,
      eventName: submission.eventName ?? null,
      eventKind: submission.eventKind,
      chillScore: submission.chillScore,
      gradingScore: submission.gradingScore,
      reviewText: submission.reviewText,
      submittedAt: submission.submittedAt,
      updatedAt: submission.updatedAt ?? submission.submittedAt,
      status: submission.status === "rejected" ? "rejected_create" : "pending_create",
    }));

  return [...ownedReviews, ...pendingCreateSubmissions].sort((lhs, rhs) => rhs.updatedAt.localeCompare(lhs.updatedAt));
}

async function submitReviewEdit(env: Env, userID: string, reviewID: string, payload: ReviewRecord): Promise<void> {
  validateReviewPayload(payload);
  const review = await requireOwnedReview(env, reviewID, userID);
  if (review.status !== "approved") {
    throw httpError("This review can't be edited right now.", 409);
  }
  await ensureNoPendingOwnedReviewChange(env, reviewID);

  const now = nowISO();
  const submissionID = `edit--${reviewID}--${payload.id}`;
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
      submitter_user_id,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'queued', NULL, ?, ?, ?, ?)
  `).bind(
    submissionID,
    sanitizeText(payload.instructorName),
    sanitizeText(payload.squadronID),
    sanitizeNullableText(payload.eventName),
    payload.eventKind,
    payload.chillScore,
    payload.gradingScore,
    sanitizeText(payload.reviewText),
    payload.submittedAt || now,
    review.submitterClientID,
    userID,
    reviewID,
    now,
    now
  ).run();
}

async function requestReviewDeletion(env: Env, userID: string, reviewID: string): Promise<void> {
  const review = await requireOwnedReview(env, reviewID, userID);
  if (review.status !== "approved") {
    throw httpError("This review can't be deleted right now.", 409);
  }
  await ensureNoPendingOwnedReviewChange(env, reviewID);

  const now = nowISO();
  const deleteRequestID = `delete--${reviewID}--${crypto.randomUUID().toLowerCase()}`;
  await env.DB.batch([
    env.DB.prepare(`
      INSERT INTO review_submissions (
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
        submitter_user_id,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'queued', NULL, ?, ?, ?, ?)
    `).bind(
      deleteRequestID,
      review.instructorName,
      review.squadronID,
      review.eventName,
      review.eventKind,
      review.chillScore,
      review.gradingScore,
      review.reviewText,
      now,
      review.submitterClientID,
      userID,
      reviewID,
      now,
      now
    ),
    env.DB.prepare(`
      UPDATE instructor_reviews
      SET status = 'rejected',
          updated_at = ?
      WHERE id = ?
    `).bind(now, reviewID),
  ]);
}

async function requireOwnedReview(env: Env, reviewID: string, userID: string | null): Promise<ReviewRecord> {
  if (!userID) {
    throw httpError("Sign in again to continue.", 401);
  }

  const review = await env.DB.prepare(`
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
      submitter_user_id AS submitterUserID,
      updated_at AS updatedAt
    FROM instructor_reviews
    WHERE id = ?
      AND submitter_user_id = ?
    LIMIT 1
  `).bind(reviewID, userID).first<ReviewRecord>();

  if (!review) {
    throw httpError("The selected review could not be found.", 404);
  }

  return review;
}

async function ensureNoPendingOwnedReviewChange(env: Env, reviewID: string): Promise<void> {
  const pendingChange = await env.DB.prepare(`
    SELECT id
    FROM review_submissions
    WHERE status = 'pending'
      AND (id LIKE ? OR id LIKE ?)
    LIMIT 1
  `).bind(`edit--${reviewID}--%`, `delete--${reviewID}--%`).first<{ id: string }>();

  if (pendingChange) {
    throw httpError("There is already a change waiting on moderation for this review.", 409);
  }
}

function decorateReviewRecord(review: ReviewRecord): ReviewRecord {
  const metadata = reviewActionMetadata(review.id);
  return {
    ...review,
    actionType: metadata.actionType,
    targetReviewID: metadata.targetReviewID,
    visibilityState: "public",
  };
}

function reviewActionMetadata(submissionID: string): { actionType: ReviewActionType; targetReviewID: string | null } {
  const match = submissionID.match(/^(edit|delete)--(.+?)--.+$/);
  if (match) {
    return {
      actionType: match[1] as ReviewActionType,
      targetReviewID: match[2] ?? null,
    };
  }

  return {
    actionType: "create",
    targetReviewID: null,
  };
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

async function resolveCommunitySubmission(env: Env, id: string): Promise<void> {
  const now = nowISO();
  await env.DB.prepare(`
    UPDATE community_submissions
    SET status = 'resolved',
        updated_at = ?
    WHERE id = ?
  `).bind(now, id).run();
}

async function dismissCommunitySubmission(env: Env, id: string): Promise<void> {
  const now = nowISO();
  await env.DB.prepare(`
    UPDATE community_submissions
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

function validateCommunitySubmissionPayload(payload: CommunitySubmissionRecord) {
  if (!payload.id || !payload.summary || !payload.message || !payload.appVersion || !payload.platform) {
    throw httpError("Incomplete community submission.", 400);
  }

  if (!["feedback", "feature_request", "support", "incorrect_gouge"].includes(payload.category)) {
    throw httpError("Invalid community submission category.", 400);
  }

  if (payload.summary.trim().length < 4 || payload.message.trim().length < 12) {
    throw httpError("Community submissions need a short summary and a bit more detail.", 400);
  }

  if (
    payload.targetKind != null &&
    !["brief", "flashcardSet", "event", "instructorReview", "generalLibrary", "other"].includes(payload.targetKind)
  ) {
    throw httpError("Invalid community submission target.", 400);
  }
}

function requireSubmitterClientID(request: Request): string {
  const clientID = request.headers.get("x-submitter-client-id")?.trim();
  if (!clientID) {
    throw httpError("Missing submitter client identifier.", 400);
  }
  return clientID;
}

function optionalSubmitterClientID(request: Request): string | null {
  return request.headers.get("x-submitter-client-id")?.trim() || null;
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

async function optionalJSON<T>(request: Request): Promise<T | null> {
  try {
    const text = await request.text();
    if (!text.trim()) return null;
    return JSON.parse(text) as T;
  } catch {
    return null;
  }
}

async function issueAppSessionBundle(
  env: Env,
  request: Request,
  userID: string,
  authTime: Date = new Date(),
): Promise<AppSessionBundle> {
  const accessTTL = Number(env.ACCESS_TOKEN_TTL_SECONDS ?? "43200");
  const refreshTTL = Number(env.REFRESH_TOKEN_TTL_SECONDS ?? "2592000");
  const refreshToken = secureRandomToken();
  const sessionID = crypto.randomUUID();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + refreshTTL * 1000);
  const accessExpiresAt = new Date(now.getTime() + accessTTL * 1000);

  await env.DB.prepare(`
    INSERT INTO user_sessions (
      id,
      user_id,
      refresh_token_hash,
      created_at,
      auth_time,
      last_seen_at,
      expires_at,
      user_agent
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    sessionID,
    userID,
    await hashOpaqueToken(env, refreshToken),
    now.toISOString(),
    authTime.toISOString(),
    now.toISOString(),
    expiresAt.toISOString(),
    sanitizeNullableText(request.headers.get("user-agent")),
  ).run();

  const accessToken = await signAppAccessToken(env, {
    sub: userID,
    sid: sessionID,
    type: "app_access",
    exp: Math.floor(accessExpiresAt.getTime() / 1000),
    authTime: Math.floor(authTime.getTime() / 1000),
  });

  return {
    accessToken,
    refreshToken,
    expiresAt: accessExpiresAt.toISOString(),
    profile: await fetchUserProfile(env, userID),
  };
}

async function signAppAccessToken(env: Env, claims: AppSessionClaims): Promise<string> {
  const payload = encodeBase64Url(JSON.stringify(claims));
  const signature = await signHmac(requiredSecret(env.AUTH_SESSION_SECRET, "AUTH_SESSION_SECRET"), payload);
  return `${payload}.${signature}`;
}

async function verifyAppAccessToken(env: Env, token: string): Promise<AppSessionClaims> {
  const [payload, signature] = token.split(".");
  if (!payload || !signature) {
    throw httpError("Invalid session.", 401);
  }

  const expectedSignature = await signHmac(requiredSecret(env.AUTH_SESSION_SECRET, "AUTH_SESSION_SECRET"), payload);
  if (!timingSafeEqual(signature, expectedSignature)) {
    throw httpError("Invalid session.", 401);
  }

  const claims = JSON.parse(decodeBase64Url(payload)) as AppSessionClaims;
  if (claims.type !== "app_access" || claims.exp <= Math.floor(Date.now() / 1000)) {
    throw httpError("Session expired.", 401);
  }

  return claims;
}

async function hashOpaqueToken(env: Env, token: string): Promise<string> {
  return signHmac(requiredSecret(env.AUTH_SESSION_SECRET, "AUTH_SESSION_SECRET"), token);
}

async function userByID(env: Env, userID: string): Promise<UserRow | null> {
  return env.DB.prepare(`
    SELECT
      id,
      display_name AS displayName,
      email,
      email_verified AS emailVerified,
      password_hash AS passwordHash,
      apple_subject AS appleSubject,
      apple_email AS appleEmail,
      squadron_id AS squadronID,
      syllabus_id AS syllabusID,
      deleted_at AS deletedAt,
      created_at AS createdAt,
      updated_at AS updatedAt
    FROM users
    WHERE id = ?
    LIMIT 1
  `).bind(userID).first<UserRow>();
}

async function userByEmail(env: Env, email: string): Promise<UserRow | null> {
  return env.DB.prepare(`
    SELECT
      id,
      display_name AS displayName,
      email,
      email_verified AS emailVerified,
      password_hash AS passwordHash,
      apple_subject AS appleSubject,
      apple_email AS appleEmail,
      squadron_id AS squadronID,
      syllabus_id AS syllabusID,
      deleted_at AS deletedAt,
      created_at AS createdAt,
      updated_at AS updatedAt
    FROM users
    WHERE lower(email) = ?
    LIMIT 1
  `).bind(email.toLowerCase()).first<UserRow>();
}

async function linkLegacySubmissions(env: Env, userID: string, email: string | null): Promise<void> {
  if (!email) return;
  const lowerEmail = email.toLowerCase();
  await env.DB.batch([
    env.DB.prepare(`
      UPDATE community_submissions
      SET submitter_user_id = ?
      WHERE submitter_user_id IS NULL AND lower(coalesce(contact_email, '')) = ?
    `).bind(userID, lowerEmail),
  ]);
}

async function createAndSendEmailCode(env: Env, userID: string, email: string, purpose: EmailCodePurpose): Promise<void> {
  const now = new Date();
  const ttl = Number(env.EMAIL_CODE_TTL_SECONDS ?? "900");
  const expiresAt = new Date(now.getTime() + ttl * 1000);
  const code = numericCode();
  const codeHash = await emailCodeHash(env, email, purpose, code);

  await env.DB.batch([
    env.DB.prepare(`
      UPDATE auth_email_codes
      SET consumed_at = ?
      WHERE email = ? AND purpose = ? AND consumed_at IS NULL
    `).bind(now.toISOString(), email, purpose),
    env.DB.prepare(`
      INSERT INTO auth_email_codes (
        id,
        user_id,
        email,
        purpose,
        code_hash,
        expires_at,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(crypto.randomUUID(), userID, email, purpose, codeHash, expiresAt.toISOString(), now.toISOString()),
  ]);

  await sendAuthEmail(env, email, purpose, code);
}

async function consumeEmailCode(
  env: Env,
  userID: string,
  email: string,
  purpose: EmailCodePurpose,
  code: string,
): Promise<void> {
  const row = await env.DB.prepare(`
    SELECT id, code_hash AS codeHash, attempts, expires_at AS expiresAt, consumed_at AS consumedAt
    FROM auth_email_codes
    WHERE user_id = ?
      AND email = ?
      AND purpose = ?
    ORDER BY created_at DESC
    LIMIT 1
  `).bind(userID, email, purpose).first<{ id: string; codeHash: string; attempts: number; expiresAt: string; consumedAt: string | null }>();

  if (!row || row.consumedAt || Date.parse(row.expiresAt) <= Date.now() || row.attempts >= 5) {
    throw genericAuthError();
  }

  const expected = await emailCodeHash(env, email, purpose, code.trim());
  if (!timingSafeEqual(expected, row.codeHash)) {
    await env.DB.prepare(`
      UPDATE auth_email_codes
      SET attempts = attempts + 1
      WHERE id = ?
    `).bind(row.id).run();
    throw genericAuthError();
  }

  await env.DB.prepare(`
    UPDATE auth_email_codes
    SET consumed_at = ?
    WHERE id = ?
  `).bind(nowISO(), row.id).run();
}

async function sendAuthEmail(env: Env, email: string, purpose: EmailCodePurpose, code: string): Promise<void> {
  const apiKey = requiredSecret(env.RESEND_API_KEY, "RESEND_API_KEY");
  const from = requiredSecret(env.AUTH_EMAIL_FROM, "AUTH_EMAIL_FROM");
  const subject = purpose === "verify_email" ? "Verify your Primary Gouge account" : "Reset your Primary Gouge password";
  const text = [
    `Your Primary Gouge code is ${code}.`,
    "It expires in 15 minutes.",
    "If you did not request this, you can ignore this email.",
  ].join("\n");

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "authorization": `Bearer ${apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [email],
      subject,
      text,
      html: `<p>Your Primary Gouge code is <strong>${escapeHTML(code)}</strong>.</p><p>It expires in 15 minutes.</p>`,
    }),
  });

  if (!response.ok) {
    throw httpError("Email delivery failed.", 502);
  }
}

async function emailCodeHash(env: Env, email: string, purpose: EmailCodePurpose, code: string): Promise<string> {
  return signHmac(requiredSecret(env.AUTH_SESSION_SECRET, "AUTH_SESSION_SECRET"), `${email.toLowerCase()}:${purpose}:${code}`);
}

async function enforceAuthRateLimit(env: Env, request: Request, action: string, maxCount: number): Promise<void> {
  const key = `${clientAddress(request)}:${action}`;
  const windowStart = Math.floor(Date.now() / 900_000) * 900_000;
  const windowISO = new Date(windowStart).toISOString();
  const existing = await env.DB.prepare(`
    SELECT count, window_start AS windowStart
    FROM auth_rate_limits
    WHERE key = ? AND action = ?
    LIMIT 1
  `).bind(key, action).first<{ count: number; windowStart: string }>();

  if (!existing || existing.windowStart !== windowISO) {
    await env.DB.prepare(`
      INSERT OR REPLACE INTO auth_rate_limits (key, action, window_start, count)
      VALUES (?, ?, ?, 1)
    `).bind(key, action, windowISO).run();
    return;
  }

  if (existing.count >= maxCount) {
    throw httpError("Too many attempts. Try again later.", 429);
  }

  await env.DB.prepare(`
    UPDATE auth_rate_limits
    SET count = count + 1
    WHERE key = ? AND action = ?
  `).bind(key, action).run();
}

async function createPasswordHash(env: Env, password: string): Promise<string> {
  const iterations = passwordHashIterations(env);
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const hash = await derivePasswordBits(password, salt, iterations, 32);
  return `pbkdf2$${iterations}$${encodeBase64Url(salt)}$${encodeBase64Url(hash)}`;
}

function passwordHashIterations(env: Env): number {
  const configured = env.PASSWORD_HASH_ITERATIONS === undefined
    ? DEFAULT_PASSWORD_HASH_ITERATIONS
    : Number(env.PASSWORD_HASH_ITERATIONS);
  if (!Number.isFinite(configured)) {
    return DEFAULT_PASSWORD_HASH_ITERATIONS;
  }

  return Math.min(
    MAX_PASSWORD_HASH_ITERATIONS,
    Math.max(MIN_PASSWORD_HASH_ITERATIONS, Math.floor(configured)),
  );
}

async function verifyAppleIdentityToken(
  env: Env,
  identityToken: string,
  expectedNonce?: string,
): Promise<{ sub: string; email: string | null; emailVerified: boolean }> {
  if (!identityToken) {
    throw httpError("Apple identity token is required.", 400);
  }
  const [headerRaw, payloadRaw, signatureRaw] = identityToken.split(".");
  if (!headerRaw || !payloadRaw || !signatureRaw) {
    throw httpError("Invalid Apple identity token.", 401);
  }

  const header = JSON.parse(decodeBase64Url(headerRaw)) as { alg?: string; kid?: string };
  const payload = JSON.parse(decodeBase64Url(payloadRaw)) as {
    iss?: string;
    aud?: string;
    exp?: number;
    sub?: string;
    email?: string;
    email_verified?: string | boolean;
    nonce?: string;
  };
  if (header.alg !== "RS256" || !header.kid) {
    throw httpError("Invalid Apple identity token.", 401);
  }

  const clientID = env.AUTH_APPLE_CLIENT_ID ?? "bolt.Primary-Gouge";
  if (
    payload.iss !== "https://appleid.apple.com" ||
    payload.aud !== clientID ||
    !payload.sub ||
    !payload.exp ||
    payload.exp <= Math.floor(Date.now() / 1000)
  ) {
    throw httpError("Invalid Apple identity token.", 401);
  }

  if (expectedNonce && payload.nonce && payload.nonce !== expectedNonce) {
    throw httpError("Invalid Apple identity token.", 401);
  }

  const jwk = await applePublicKey(header.kid);
  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    decodeBase64UrlToBytes(signatureRaw) as BufferSource,
    new TextEncoder().encode(`${headerRaw}.${payloadRaw}`),
  );
  if (!valid) {
    throw httpError("Invalid Apple identity token.", 401);
  }

  return {
    sub: payload.sub,
    email: normalizeEmail(payload.email),
    emailVerified: payload.email_verified === true || payload.email_verified === "true",
  };
}

async function applePublicKey(kid: string): Promise<JsonWebKey> {
  const response = await fetch("https://appleid.apple.com/auth/keys");
  if (!response.ok) {
    throw httpError("Could not verify Apple sign-in.", 502);
  }
  const keys = await response.json() as { keys?: JsonWebKey[] };
  const key = keys.keys?.find((candidate) => (candidate as JsonWebKey & { kid?: string }).kid === kid);
  if (!key) {
    throw httpError("Could not verify Apple sign-in.", 401);
  }
  return key;
}

async function revokeAppleAuthorizationIfConfigured(env: Env, authorizationCode: string): Promise<void> {
  if (!env.APPLE_TEAM_ID || !env.APPLE_KEY_ID || !env.APPLE_PRIVATE_KEY || !env.AUTH_APPLE_CLIENT_ID) {
    console.warn("apple_revocation_skipped_missing_configuration");
    return;
  }

  const clientSecret = await appleClientSecret(env);
  const tokenBody = new URLSearchParams({
    client_id: env.AUTH_APPLE_CLIENT_ID,
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: "authorization_code",
  });
  const tokenResponse = await fetch("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: tokenBody,
  });
  if (!tokenResponse.ok) {
    console.warn("apple_token_exchange_failed", { status: tokenResponse.status });
    return;
  }
  const tokenPayload = await tokenResponse.json() as { refresh_token?: string; access_token?: string };
  const token = tokenPayload.refresh_token ?? tokenPayload.access_token;
  if (!token) return;

  const revokeBody = new URLSearchParams({
    client_id: env.AUTH_APPLE_CLIENT_ID,
    client_secret: clientSecret,
    token,
  });
  const revokeResponse = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: revokeBody,
  });
  if (!revokeResponse.ok) {
    console.warn("apple_revocation_failed", { status: revokeResponse.status });
  }
}

async function appleClientSecret(env: Env): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = encodeBase64Url(JSON.stringify({ alg: "ES256", kid: env.APPLE_KEY_ID }));
  const payload = encodeBase64Url(JSON.stringify({
    iss: env.APPLE_TEAM_ID,
    iat: now,
    exp: now + 300,
    aud: "https://appleid.apple.com",
    sub: env.AUTH_APPLE_CLIENT_ID,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(requiredSecret(env.APPLE_PRIVATE_KEY, "APPLE_PRIVATE_KEY")),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${payload}`),
  );
  return `${header}.${payload}.${encodeBase64Url(new Uint8Array(signature))}`;
}

function requireRecentAuthentication(user: AuthenticatedUser): void {
  const tenMinutes = 600;
  if (Math.floor(Date.now() / 1000) - user.authTime > tenMinutes) {
    throw httpError("Recent sign-in is required before deleting this account.", 401);
  }
}

function normalizeEmail(value: string | null | undefined): string | null {
  const normalized = value?.trim().toLowerCase() ?? "";
  if (!normalized) return null;
  return normalized;
}

function requireEmail(value: string | null | undefined): string {
  const email = normalizeEmail(value);
  if (!email || !email.includes("@") || !email.includes(".")) {
    throw httpError("Enter a valid email address.", 400);
  }
  return email;
}

function requireStrongPassword(password: string): string {
  if (password.length < 10) {
    throw httpError("Password must be at least 10 characters.", 400);
  }
  return password;
}

function normalizedProfileChoice(value: string | null | undefined): string | null {
  const normalized = sanitizeNullableText(value);
  return normalized ?? null;
}

function normalizedSyllabusID(value: SyllabusID | null | undefined): SyllabusID | null {
  if (value == null) return null;
  if (value === "delta" || value === "echo" || value === "not_sure") return value;
  throw httpError("Invalid syllabus selection.", 400);
}

function genericAuthError(): Error & { status: number } {
  return httpError("Sign-in failed.", 401);
}

function clientAddress(request: Request): string {
  return request.headers.get("cf-connecting-ip") ?? request.headers.get("x-forwarded-for") ?? "unknown";
}

function numericCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(4));
  const value = new DataView(bytes.buffer).getUint32(0) % 1_000_000;
  return value.toString().padStart(6, "0");
}

function secureRandomToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return encodeBase64Url(bytes);
}

function requiredSecret(value: string | undefined, name: string): string {
  if (!value) {
    throw httpError(`${name} is not configured.`, 500);
  }
  return value;
}

function normalizedSupabaseURL(env: Env): string {
  const value = env.SUPABASE_URL?.trim().replace(/\/+$/, "");
  if (!value) {
    throw httpError("SUPABASE_URL is not configured.", 500);
  }
  return value;
}

function requiredSupabasePublishableKey(env: Env): string {
  const value = env.SUPABASE_PUBLISHABLE_KEY?.trim();
  if (!value) {
    throw httpError("SUPABASE_PUBLISHABLE_KEY is not configured.", 500);
  }
  return value;
}

function escapeHTML(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const bytes = decodeBase64ToBytes(base64);
  const copy = new ArrayBuffer(bytes.byteLength);
  new Uint8Array(copy).set(bytes);
  return copy;
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
  if (!Number.isSafeInteger(iterations) || iterations <= 0 || iterations > MAX_PASSWORD_HASH_ITERATIONS) {
    return false;
  }

  let salt: Uint8Array;
  let expected: Uint8Array;
  let hash: Uint8Array;
  try {
    salt = decodeBase64UrlToBytes(saltRaw);
    expected = decodeBase64UrlToBytes(expectedRaw);
    hash = await derivePasswordBits(password, salt, iterations, expected.byteLength);
  } catch {
    return false;
  }

  return timingSafeEqualBytes(hash, expected);
}

async function derivePasswordBits(password: string, salt: Uint8Array, iterations: number, byteLength: number): Promise<Uint8Array> {
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
      salt: salt as BufferSource,
      iterations,
    },
    key,
    byteLength * 8,
  );

  return new Uint8Array(bits);
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

function decodeBase64ToBytes(value: string): Uint8Array {
  const binary = atob(value.padEnd(Math.ceil(value.length / 4) * 4, "="));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}
