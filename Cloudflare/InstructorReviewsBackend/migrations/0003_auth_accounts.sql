CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    display_name TEXT,
    email TEXT UNIQUE,
    email_verified INTEGER NOT NULL DEFAULT 0,
    password_hash TEXT,
    apple_subject TEXT UNIQUE,
    apple_email TEXT,
    squadron_id TEXT,
    syllabus_id TEXT CHECK (syllabus_id IN ('delta', 'echo', 'not_sure') OR syllabus_id IS NULL),
    deleted_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id TEXT NOT NULL,
    role TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (user_id, role),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    refresh_token_hash TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL,
    auth_time TEXT NOT NULL,
    last_seen_at TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    revoked_at TEXT,
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auth_email_codes (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    email TEXT NOT NULL,
    purpose TEXT NOT NULL CHECK (purpose IN ('verify_email', 'reset_password')),
    code_hash TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at TEXT NOT NULL,
    consumed_at TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auth_rate_limits (
    key TEXT NOT NULL,
    action TEXT NOT NULL,
    window_start TEXT NOT NULL,
    count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (key, action)
);

ALTER TABLE instructor_reviews ADD COLUMN submitter_user_id TEXT;
ALTER TABLE review_submissions ADD COLUMN submitter_user_id TEXT;
ALTER TABLE gouge_reports ADD COLUMN submitter_user_id TEXT;
ALTER TABLE community_submissions ADD COLUMN submitter_user_id TEXT;

CREATE INDEX IF NOT EXISTS idx_users_apple_subject
ON users(apple_subject);

CREATE INDEX IF NOT EXISTS idx_users_email
ON users(email);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user
ON user_sessions(user_id, expires_at DESC);

CREATE INDEX IF NOT EXISTS idx_auth_email_codes_lookup
ON auth_email_codes(email, purpose, expires_at DESC);

CREATE INDEX IF NOT EXISTS idx_instructor_reviews_submitter_user
ON instructor_reviews(submitter_user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_review_submissions_submitter_user
ON review_submissions(submitter_user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_gouge_reports_submitter_user
ON gouge_reports(submitter_user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_submissions_submitter_user
ON community_submissions(submitter_user_id, updated_at DESC);
