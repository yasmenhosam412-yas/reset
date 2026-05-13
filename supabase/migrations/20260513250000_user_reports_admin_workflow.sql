-- Admin moderation: flag on profiles + report lifecycle + RPCs (RLS-safe; no service key in clients).

alter table public.profiles
  add column if not exists is_admin boolean not null default false;

comment on column public.profiles.is_admin is
  'When true, user may call admin_* RPCs for moderation. Set only via SQL Dashboard or service role.';

alter table public.user_reports
  add column if not exists status text not null default 'pending';

alter table public.user_reports
  add column if not exists resolution text;

alter table public.user_reports
  add column if not exists admin_notes text;

alter table public.user_reports
  add column if not exists reviewed_by uuid references public.profiles (id) on delete set null;

alter table public.user_reports
  add column if not exists reviewed_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'user_reports_status_check'
  ) then
    alter table public.user_reports
      add constraint user_reports_status_check
      check (status in ('pending', 'reviewing', 'resolved', 'dismissed'));
  end if;
end $$;

create index if not exists user_reports_status_created_idx
  on public.user_reports (status, created_at desc);

-- Stable admin check (reads profiles; security definer avoids RLS recursion on profiles).
create or replace function public.is_admin (uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select p.is_admin
      from public.profiles p
      where p.id = uid
    ),
    false
  );
$$;

revoke all on function public.is_admin (uuid) from public;
grant execute on function public.is_admin (uuid) to authenticated;

-- Admins can read all reports (reporters still have no select policy unless added later).
drop policy if exists "user_reports_select_admin" on public.user_reports;

create policy "user_reports_select_admin"
  on public.user_reports for select
  to authenticated
  using (public.is_admin (auth.uid()));

-- List reports with usernames (admin only).
create or replace function public.admin_list_user_reports (p_limit int default 100)
returns table (
  id uuid,
  reporter_id uuid,
  reported_user_id uuid,
  reporter_username text,
  reported_username text,
  reason text,
  details text,
  context jsonb,
  status text,
  resolution text,
  admin_notes text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    r.id,
    r.reporter_id,
    r.reported_user_id,
    pr.username as reporter_username,
    pd.username as reported_username,
    r.reason,
    r.details,
    r.context,
    r.status,
    r.resolution,
    r.admin_notes,
    r.reviewed_by,
    r.reviewed_at,
    r.created_at
  from public.user_reports r
  join public.profiles pr on pr.id = r.reporter_id
  join public.profiles pd on pd.id = r.reported_user_id
  where public.is_admin (auth.uid())
  order by r.created_at desc
  limit least(coalesce(nullif(p_limit, 0), 100), 500);
$$;

revoke all on function public.admin_list_user_reports (int) from public;
grant execute on function public.admin_list_user_reports (int) to authenticated;

-- Update report outcome (admin only).
create or replace function public.admin_update_user_report (
  p_report_id uuid,
  p_status text,
  p_resolution text default null,
  p_admin_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  updated int;
begin
  if not public.is_admin (auth.uid()) then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if p_status is null
     or p_status not in ('pending', 'reviewing', 'resolved', 'dismissed') then
    raise exception 'invalid status';
  end if;

  update public.user_reports
  set
    status = p_status,
    resolution = nullif(trim(p_resolution), ''),
    admin_notes = nullif(trim(p_admin_notes), ''),
    reviewed_by = auth.uid(),
    reviewed_at = now()
  where id = p_report_id;

  get diagnostics updated = row_count;
  if updated = 0 then
    raise exception 'report not found';
  end if;
end;
$$;

revoke all on function public.admin_update_user_report (uuid, text, text, text) from public;
grant execute on function public.admin_update_user_report (uuid, text, text, text) to authenticated;

-- Promote a moderator (run in SQL editor after migration; use your auth user id from auth.users):
-- update public.profiles set is_admin = true where id = 'YOUR_USER_UUID';

-- Prevent self-service toggling of is_admin (promotions use SQL as DB superuser in the dashboard).
create or replace function public.profiles_prevent_is_admin_toggle ()
returns trigger
language plpgsql
as $$
begin
  if old.is_admin is distinct from new.is_admin then
    if current_user not in ('postgres', 'supabase_admin') then
      raise exception 'is_admin cannot be changed via the client API';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_prevent_is_admin_toggle on public.profiles;

create trigger trg_profiles_prevent_is_admin_toggle
  before update on public.profiles
  for each row
  execute function public.profiles_prevent_is_admin_toggle ();
