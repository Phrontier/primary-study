CREATE TABLE IF NOT EXISTS contributor_bans (
  user_id TEXT PRIMARY KEY,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  reason TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
