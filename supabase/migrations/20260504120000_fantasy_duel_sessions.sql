-- Fantasy duel: both players draft 3 of 5 shared-seed hands; trios compared online.

create table if not exists public.fantasy_duel_sessions (
  challenge_id uuid primary key
    references public.game_challenges (id) on delete cascade,
  deck_seed integer not null,
  from_trio jsonb,
  to_trio jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists fantasy_duel_sessions_updated_idx
  on public.fantasy_duel_sessions (updated_at desc);

alter table public.fantasy_duel_sessions enable row level security;

drop policy if exists "fantasy_duel_sessions_select" on public.fantasy_duel_sessions;
create policy "fantasy_duel_sessions_select"
  on public.fantasy_duel_sessions for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = fantasy_duel_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "fantasy_duel_sessions_insert" on public.fantasy_duel_sessions;
create policy "fantasy_duel_sessions_insert"
  on public.fantasy_duel_sessions for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = fantasy_duel_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

drop policy if exists "fantasy_duel_sessions_update" on public.fantasy_duel_sessions;
create policy "fantasy_duel_sessions_update"
  on public.fantasy_duel_sessions for update
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = fantasy_duel_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = fantasy_duel_sessions.challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );

create or replace function public.ensure_fantasy_duel_session(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seed integer;
begin
  v_seed := abs(hashtext(p_challenge_id::text));
  if v_seed = 0 then
    v_seed := 1;
  end if;

  insert into public.fantasy_duel_sessions (challenge_id, deck_seed)
  values (p_challenge_id, v_seed)
  on conflict (challenge_id) do nothing;
end;
$$;

revoke all on function public.ensure_fantasy_duel_session(uuid) from public;
grant execute on function public.ensure_fantasy_duel_session(uuid) to authenticated;

alter table public.fantasy_duel_sessions replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'fantasy_duel_sessions'
  ) then
    alter publication supabase_realtime add table public.fantasy_duel_sessions;
  end if;
end $$;
