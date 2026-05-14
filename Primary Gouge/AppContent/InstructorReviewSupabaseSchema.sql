create table if not exists public.review_submissions (
    id text primary key,
    instructor_name text not null,
    squadron_id text not null,
    event_name text,
    event_kind text not null check (event_kind in ('sim', 'flight')),
    chill_score int not null,
    grading_score int not null,
    review_text text not null,
    submitted_at timestamptz not null default now(),
    status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
    submitter_client_id text not null,
    updated_at timestamptz not null default now()
);

create table if not exists public.instructor_reviews (
    id text primary key,
    instructor_name text not null,
    squadron_id text not null,
    event_name text,
    event_kind text not null check (event_kind in ('sim', 'flight')),
    chill_score int not null,
    grading_score int not null,
    review_text text not null,
    submitted_at timestamptz not null,
    status text not null default 'approved' check (status in ('approved', 'rejected')),
    submitter_client_id text,
    updated_at timestamptz not null default now()
);

create table if not exists public.gouge_reports (
    id text primary key,
    target_kind text not null check (target_kind in ('instructor', 'review')),
    instructor_id text not null,
    review_id text,
    instructor_name text not null,
    squadron_id text not null,
    event_name text,
    event_kind text check (event_kind in ('sim', 'flight')),
    review_text text,
    reason_title text not null,
    note text,
    submitted_at timestamptz not null default now(),
    status text not null default 'open' check (status in ('open', 'dismissed', 'resolved')),
    submitter_client_id text not null,
    updated_at timestamptz not null default now()
);

create table if not exists public.moderator_users (
    email text primary key,
    is_active boolean not null default true,
    created_at timestamptz not null default now()
);
