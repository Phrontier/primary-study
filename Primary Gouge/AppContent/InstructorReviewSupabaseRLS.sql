begin;

create schema if not exists private;

create or replace function private.request_submitter_client_id()
returns text
language sql
stable
as $$
    select nullif(current_setting('request.headers', true)::json->>'x-submitter-client-id', '');
$$;

create or replace function private.is_active_moderator()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
    select exists (
        select 1
        from public.moderator_users
        where is_active = true
          and lower(email) = lower(coalesce(auth.jwt()->>'email', ''))
    );
$$;

revoke all on function private.is_active_moderator() from public;
revoke all on function private.request_submitter_client_id() from public;
grant execute on function private.is_active_moderator() to anon, authenticated;
grant execute on function private.request_submitter_client_id() to anon, authenticated;

grant select on table public.instructor_reviews to anon, authenticated;
grant insert on table public.review_submissions to anon, authenticated;
grant select on table public.review_submissions to anon, authenticated;
grant update on table public.review_submissions to authenticated;
grant insert on table public.gouge_reports to anon, authenticated;
grant select on table public.gouge_reports to anon, authenticated;
grant update on table public.gouge_reports to authenticated;
grant insert, delete on table public.instructor_reviews to authenticated;

alter table public.instructor_reviews enable row level security;
alter table public.review_submissions enable row level security;
alter table public.gouge_reports enable row level security;
alter table public.moderator_users enable row level security;

drop policy if exists "public_can_read_approved_instructor_reviews" on public.instructor_reviews;
create policy "public_can_read_approved_instructor_reviews"
on public.instructor_reviews
for select
to anon, authenticated
using (status = 'approved');

drop policy if exists "moderators_can_publish_instructor_reviews" on public.instructor_reviews;
create policy "moderators_can_publish_instructor_reviews"
on public.instructor_reviews
for insert
to authenticated
with check (
    private.is_active_moderator()
    and status = 'approved'
);

drop policy if exists "moderators_can_remove_instructor_reviews" on public.instructor_reviews;
create policy "moderators_can_remove_instructor_reviews"
on public.instructor_reviews
for delete
to authenticated
using (private.is_active_moderator());

drop policy if exists "submitters_can_create_review_submissions" on public.review_submissions;
create policy "submitters_can_create_review_submissions"
on public.review_submissions
for insert
to anon, authenticated
with check (
    status = 'pending'
    and submitter_client_id is not null
    and submitter_client_id = private.request_submitter_client_id()
);

drop policy if exists "submitters_can_read_their_review_submissions" on public.review_submissions;
create policy "submitters_can_read_their_review_submissions"
on public.review_submissions
for select
to anon, authenticated
using (
    submitter_client_id is not null
    and submitter_client_id = private.request_submitter_client_id()
);

drop policy if exists "moderators_can_read_review_submissions" on public.review_submissions;
create policy "moderators_can_read_review_submissions"
on public.review_submissions
for select
to authenticated
using (private.is_active_moderator());

drop policy if exists "moderators_can_update_review_submissions" on public.review_submissions;
create policy "moderators_can_update_review_submissions"
on public.review_submissions
for update
to authenticated
using (private.is_active_moderator())
with check (private.is_active_moderator());

drop policy if exists "submitters_can_create_reports" on public.gouge_reports;
create policy "submitters_can_create_reports"
on public.gouge_reports
for insert
to anon, authenticated
with check (
    status = 'open'
    and submitter_client_id is not null
    and submitter_client_id = private.request_submitter_client_id()
);

drop policy if exists "submitters_can_read_their_reports" on public.gouge_reports;
create policy "submitters_can_read_their_reports"
on public.gouge_reports
for select
to anon, authenticated
using (
    submitter_client_id is not null
    and submitter_client_id = private.request_submitter_client_id()
);

drop policy if exists "moderators_can_read_reports" on public.gouge_reports;
create policy "moderators_can_read_reports"
on public.gouge_reports
for select
to authenticated
using (private.is_active_moderator());

drop policy if exists "moderators_can_update_reports" on public.gouge_reports;
create policy "moderators_can_update_reports"
on public.gouge_reports
for update
to authenticated
using (private.is_active_moderator())
with check (private.is_active_moderator());

drop policy if exists "nobody_reads_moderator_users_directly" on public.moderator_users;
create policy "nobody_reads_moderator_users_directly"
on public.moderator_users
for select
to authenticated
using (false);

commit;
