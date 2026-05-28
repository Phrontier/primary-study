CREATE TABLE IF NOT EXISTS instructor_reviews (
    id TEXT PRIMARY KEY,
    instructor_name TEXT NOT NULL,
    squadron_id TEXT NOT NULL,
    event_name TEXT,
    event_kind TEXT NOT NULL CHECK (event_kind IN ('sim', 'flight')),
    chill_score INTEGER NOT NULL,
    grading_score INTEGER NOT NULL,
    review_text TEXT NOT NULL,
    submitted_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'approved' CHECK (status IN ('approved', 'rejected')),
    submitter_client_id TEXT,
    source_submission_id TEXT UNIQUE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS review_submissions (
    id TEXT PRIMARY KEY,
    instructor_name TEXT NOT NULL,
    squadron_id TEXT NOT NULL,
    event_name TEXT,
    event_kind TEXT NOT NULL CHECK (event_kind IN ('sim', 'flight')),
    chill_score INTEGER NOT NULL,
    grading_score INTEGER NOT NULL,
    review_text TEXT NOT NULL,
    submitted_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    moderation_state TEXT NOT NULL DEFAULT 'queued' CHECK (moderation_state IN ('queued', 'screened_clean', 'needs_human_review', 'auto_rejected')),
    moderation_summary TEXT,
    submitter_client_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS gouge_reports (
    id TEXT PRIMARY KEY,
    target_kind TEXT NOT NULL CHECK (target_kind IN ('instructor', 'review')),
    instructor_id TEXT NOT NULL,
    review_id TEXT,
    instructor_name TEXT NOT NULL,
    squadron_id TEXT NOT NULL,
    event_name TEXT,
    event_kind TEXT CHECK (event_kind IN ('sim', 'flight')),
    review_text TEXT,
    reason_title TEXT NOT NULL,
    note TEXT,
    submitted_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'dismissed', 'resolved')),
    submitter_client_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS moderator_accounts (
    email TEXT PRIMARY KEY,
    password_hash TEXT NOT NULL,
    display_name TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_instructor_reviews_status_submitted_at
ON instructor_reviews(status, submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_review_submissions_submitter
ON review_submissions(submitter_client_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_review_submissions_pending
ON review_submissions(status, moderation_state, submitted_at ASC);

CREATE INDEX IF NOT EXISTS idx_gouge_reports_submitter
ON gouge_reports(submitter_client_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_gouge_reports_open
ON gouge_reports(status, submitted_at DESC);
