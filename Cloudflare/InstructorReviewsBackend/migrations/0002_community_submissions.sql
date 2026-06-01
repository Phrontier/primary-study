CREATE TABLE IF NOT EXISTS community_submissions (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL CHECK (category IN ('feedback', 'feature_request', 'support', 'incorrect_gouge')),
    summary TEXT NOT NULL,
    message TEXT NOT NULL,
    contact_email TEXT,
    target_kind TEXT CHECK (target_kind IN ('brief', 'flashcardSet', 'event', 'instructorReview', 'generalLibrary', 'other')),
    target_id TEXT,
    target_title TEXT,
    target_context TEXT,
    app_version TEXT NOT NULL,
    build_number TEXT,
    platform TEXT NOT NULL,
    submitted_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'dismissed', 'resolved')),
    submitter_client_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_community_submissions_submitter
ON community_submissions(submitter_client_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_submissions_open
ON community_submissions(status, submitted_at DESC);
