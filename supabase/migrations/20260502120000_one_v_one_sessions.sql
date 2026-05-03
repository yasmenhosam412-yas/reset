-- 1v1 mini soccer: shared session for online matches (host = challenge from_user).

create table if not exists public.one_v_one_sessions (
  challenge_id uuid primary key
    references public.game_challenges (id) on delete cascade,
  ball_x double precision not null default 0.5,
  ball_y double precision not null default 0.5,
  ball_vx double precision not null default 0,
  ball_vy double precision not null default 0,
  from_px double precision not null default 0.12,
  from_py double precision not null default 0.5,
  to_px double precision not null default 0.88,
  to_py double precision not null default 0.5,
  score_from integer not null default 0
    check (score_from >= 0 and score_from <= 99),
  score_to integer not null default 0
    check (score_to >= 0 and score_to <= 99),
  ends_at timestamptz,
  guest_kick_req integer not null default 0
    check (guest_kick_req >= 0 and guest_kick_req < 1000000),
  updated_at timestamptz not null default now()
);

create index if not exists one_v_one_sessions_updated_idx
  on public.one_v_one_sessions (updated_at desc);

alter table public.one_v_one_sessions enable row level security;

drop policy if exists "one_v_one_sessions_select" on public.one_v_one_sessions;
create policy "one_v_one_sessions_select"
  on public.one_v_one_sessions for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = one_v_one_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "one_v_one_sessions_insert" on public.one_v_one_sessions;
create policy "one_v_one_sessions_insert"
  on public.one_v_one_sessions for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = one_v_one_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "one_v_one_sessions_update" on public.one_v_one_sessions;
create policy "one_v_one_sessions_update"
  on public.one_v_one_sessions for update
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = one_v_one_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = one_v_one_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

create or replace function public.ensure_one_v_one_session(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.game_challenges gc
    where gc.id = p_challenge_id
      and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
  ) then
    raise exception 'not a participant';
  end if;

  insert into public.one_v_one_sessions (challenge_id)
  values (p_challenge_id)
  on conflict (challenge_id) do nothing;
end;
$$;

revoke all on function public.ensure_one_v_one_session(uuid) from public;
grant execute on function public.ensure_one_v_one_session(uuid) to authenticated;

create or replace function public.bump_guest_kick_req(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  update public.one_v_one_sessions s
  set
    guest_kick_req = s.guest_kick_req + 1,
    updated_at = now()
  from public.game_challenges gc
  where s.challenge_id = p_challenge_id
    and gc.id = s.challenge_id
    and gc.to_user_id = auth.uid();

  get diagnostics n = row_count;
  if n = 0 then
    raise exception 'not guest or no session row';
  end if;
end;
$$;

revoke all on function public.bump_guest_kick_req(uuid) from public;
grant execute on function public.bump_guest_kick_req(uuid) to authenticated;

alter table public.one_v_one_sessions replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'one_v_one_sessions'
  ) then
    alter publication supabase_realtime add table public.one_v_one_sessions;
  end if;
end $$;
