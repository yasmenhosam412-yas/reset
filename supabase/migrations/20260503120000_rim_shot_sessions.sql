-- Rim shot (free-throw duel): shared scores + turn for online challenges.

create table if not exists public.rim_shot_sessions (
  challenge_id uuid primary key
    references public.game_challenges (id) on delete cascade,
  score_from integer not null default 0
    check (score_from >= 0 and score_from <= 32),
  score_to integer not null default 0
    check (score_to >= 0 and score_to <= 32),
  whose_turn text not null default 'from'
    check (whose_turn in ('from', 'to')),
  round_seq integer not null default 0
    check (round_seq >= 0),
  last_power double precision,
  last_aim double precision,
  last_made boolean,
  status text not null default 'playing'
    check (status in ('playing', 'done')),
  updated_at timestamptz not null default now()
);

create index if not exists rim_shot_sessions_updated_idx
  on public.rim_shot_sessions (updated_at desc);

alter table public.rim_shot_sessions enable row level security;

drop policy if exists "rim_shot_sessions_select" on public.rim_shot_sessions;
create policy "rim_shot_sessions_select"
  on public.rim_shot_sessions for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rim_shot_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "rim_shot_sessions_insert" on public.rim_shot_sessions;
create policy "rim_shot_sessions_insert"
  on public.rim_shot_sessions for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rim_shot_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "rim_shot_sessions_update" on public.rim_shot_sessions;
create policy "rim_shot_sessions_update"
  on public.rim_shot_sessions for update
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rim_shot_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = rim_shot_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

create or replace function public.ensure_rim_shot_session(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.rim_shot_sessions (challenge_id)
  values (p_challenge_id)
  on conflict (challenge_id) do nothing;
end;
$$;

revoke all on function public.ensure_rim_shot_session(uuid) from public;
grant execute on function public.ensure_rim_shot_session(uuid) to authenticated;

alter table public.rim_shot_sessions replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'rim_shot_sessions'
  ) then
    alter publication supabase_realtime add table public.rim_shot_sessions;
  end if;
end $$;
