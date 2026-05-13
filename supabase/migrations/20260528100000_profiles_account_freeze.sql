-- Temporary account freeze (moderation): [profiles.frozen_until] + admin tooling.

alter table public.profiles
  add column if not exists frozen_until timestamptz;

comment on column public.profiles.frozen_until is
  'When set in the future, the account is suspended (client sign-out + selected write RLS).';

-- Invoker: reads caller''s profile row under normal RLS.
create or replace function public.auth_user_is_frozen ()
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.frozen_until is not null
      and p.frozen_until > now()
  );
$$;

revoke all on function public.auth_user_is_frozen () from public;
grant execute on function public.auth_user_is_frozen () to authenticated;

-- ---------------------------------------------------------------------------
-- RLS: block most self-initiated writes while frozen (reports insert still allowed).
-- ---------------------------------------------------------------------------

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id and not public.auth_user_is_frozen ())
  with check (auth.uid() = id and not public.auth_user_is_frozen ());

drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own"
  on public.posts for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and not public.auth_user_is_frozen ()
  );

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own"
  on public.posts for update
  to authenticated
  using (auth.uid() = user_id and not public.auth_user_is_frozen ())
  with check (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own"
  on public.posts for delete
  to authenticated
  using (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "post_comments_insert_own" on public.post_comments;
create policy "post_comments_insert_own"
  on public.post_comments for insert
  to authenticated
  with check (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "post_comments_delete_own" on public.post_comments;
create policy "post_comments_delete_own"
  on public.post_comments for delete
  to authenticated
  using (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "post_saves_insert_own" on public.post_saves;
create policy "post_saves_insert_own"
  on public.post_saves for insert
  to authenticated
  with check (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "post_saves_update_own" on public.post_saves;
create policy "post_saves_update_own"
  on public.post_saves for update
  to authenticated
  using (auth.uid() = user_id and not public.auth_user_is_frozen ())
  with check (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "post_saves_delete_own" on public.post_saves;
create policy "post_saves_delete_own"
  on public.post_saves for delete
  to authenticated
  using (auth.uid() = user_id and not public.auth_user_is_frozen ());

drop policy if exists "friend_requests_insert_as_sender" on public.friend_requests;
create policy "friend_requests_insert_as_sender"
  on public.friend_requests for insert
  to authenticated
  with check (auth.uid() = from_user_id and not public.auth_user_is_frozen ());

drop policy if exists "friend_requests_update_involved" on public.friend_requests;
create policy "friend_requests_update_involved"
  on public.friend_requests for update
  to authenticated
  using (
    (auth.uid() = from_user_id or auth.uid() = to_user_id)
    and not public.auth_user_is_frozen ()
  )
  with check (
    (auth.uid() = from_user_id or auth.uid() = to_user_id)
    and not public.auth_user_is_frozen ()
  );

drop policy if exists "game_challenges_insert_as_sender" on public.game_challenges;
create policy "game_challenges_insert_as_sender"
  on public.game_challenges for insert
  to authenticated
  with check (auth.uid() = from_user_id and not public.auth_user_is_frozen ());

drop policy if exists "game_challenges_update_involved" on public.game_challenges;
create policy "game_challenges_update_involved"
  on public.game_challenges for update
  to authenticated
  using (
    (auth.uid() = from_user_id or auth.uid() = to_user_id)
    and not public.auth_user_is_frozen ()
  )
  with check (
    (auth.uid() = from_user_id or auth.uid() = to_user_id)
    and not public.auth_user_is_frozen ()
  );

-- Block RPC path that bypasses post RLS.
create or replace function public.block_user (p_blocked uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  if exists (
    select 1
    from public.profiles p
    where p.id = me
      and p.frozen_until is not null
      and p.frozen_until > now()
  ) then
    raise exception 'account suspended' using errcode = '42501';
  end if;

  if p_blocked is null or p_blocked = me then
    raise exception 'invalid blocked user';
  end if;

  insert into public.user_blocks (blocker_user_id, blocked_user_id)
  values (me, p_blocked)
  on conflict (blocker_user_id, blocked_user_id) do nothing;

  delete from public.friend_requests fr
  where (fr.from_user_id = me and fr.to_user_id = p_blocked)
     or (fr.from_user_id = p_blocked and fr.to_user_id = me);

  delete from public.game_challenges gc
  where (gc.from_user_id = me and gc.to_user_id = p_blocked)
     or (gc.from_user_id = p_blocked and gc.to_user_id = me);
end;
$$;

-- ---------------------------------------------------------------------------
-- Admin list / update (replace signatures).
-- ---------------------------------------------------------------------------

drop function if exists public.admin_list_user_reports (int);

create or replace function public.admin_list_user_reports (p_limit int default 100)
returns table (
  id uuid,
  reporter_id uuid,
  reported_user_id uuid,
  reporter_username text,
  reported_username text,
  reported_frozen_until timestamptz,
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
    pd.frozen_until as reported_frozen_until,
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

drop function if exists public.admin_update_user_report (uuid, text, text, text);

create or replace function public.admin_update_user_report (
  p_report_id uuid,
  p_status text,
  p_resolution text default null,
  p_admin_notes text default null,
  p_freeze_days int default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  updated int;
  reported uuid;
  d int;
begin
  if not public.is_admin (auth.uid()) then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  if p_status is null
     or p_status not in ('pending', 'reviewing', 'resolved', 'dismissed') then
    raise exception 'invalid status';
  end if;

  select r.reported_user_id into reported
  from public.user_reports r
  where r.id = p_report_id;

  if not found then
    raise exception 'report not found';
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

  if p_freeze_days is not null then
    d := p_freeze_days;
    if d < 0 or d > 365 then
      raise exception 'freeze days must be between 0 and 365';
    end if;

    if d = 0 then
      update public.profiles
      set frozen_until = null
      where id = reported;
    else
      update public.profiles p
      set frozen_until =
            greatest(coalesce(p.frozen_until, '-infinity'::timestamptz), now())
            + make_interval(days => d)
      where p.id = reported;
    end if;
  end if;
end;
$$;

revoke all on function public.admin_update_user_report (uuid, text, text, text, int) from public;
grant execute on function public.admin_update_user_report (uuid, text, text, text, int) to authenticated;

-- Block self-service changes to [frozen_until] (admins use RPC / SQL as superuser).
create or replace function public.profiles_prevent_frozen_until_client_toggle ()
returns trigger
language plpgsql
as $$
begin
  if old.frozen_until is distinct from new.frozen_until then
    if current_user not in ('postgres', 'supabase_admin') then
      raise exception 'frozen_until cannot be changed via the client API';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_prevent_frozen_until_client_toggle on public.profiles;

create trigger trg_profiles_prevent_frozen_until_client_toggle
  before update on public.profiles
  for each row
  execute function public.profiles_prevent_frozen_until_client_toggle ();
