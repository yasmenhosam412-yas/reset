-- Weekly lineup "races": players submit saved [profiles.team_squad] for scoring modes; leaderboard per race_key.

create table if not exists public.team_lineup_race_entries (
  race_key text not null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  score integer not null check (score >= 0),
  team_name text not null default '',
  submitted_at timestamptz not null default now(),
  primary key (race_key, user_id)
);

create index if not exists team_lineup_race_entries_race_score_idx
  on public.team_lineup_race_entries (race_key, score desc, submitted_at asc);

alter table public.team_lineup_race_entries enable row level security;

drop policy if exists "team_lineup_race_entries_select_all" on public.team_lineup_race_entries;
create policy "team_lineup_race_entries_select_all"
  on public.team_lineup_race_entries for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- Score helpers (players = squad JSON "players" array, length 6)
-- ---------------------------------------------------------------------------
create or replace function public._lineup_race_score(players jsonb, p_mode text)
returns integer
language plpgsql
immutable
as $$
declare
  i int;
  el jsonb;
  a int;
  d int;
  sp int;
  st int;
  m int;
  total int := 0;
begin
  if players is null or jsonb_array_length(players) <> 6 then
    return 0;
  end if;

  if p_mode = 'power' then
    for i in 0..5 loop
      el := players->i;
      a := greatest(least((el->>'attack')::int, 99), 0);
      d := greatest(least((el->>'defense')::int, 99), 0);
      sp := greatest(least((el->>'speed')::int, 99), 0);
      st := greatest(least((el->>'stamina')::int, 99), 0);
      total := total + a + d + sp + st;
    end loop;
    return total;
  elsif p_mode = 'speed' then
    for i in 0..5 loop
      el := players->i;
      sp := greatest(least((el->>'speed')::int, 99), 0);
      st := greatest(least((el->>'stamina')::int, 99), 0);
      total := total + sp * 2 + st;
    end loop;
    return total;
  elsif p_mode = 'balance' then
    for i in 0..5 loop
      el := players->i;
      a := greatest(least((el->>'attack')::int, 99), 0);
      d := greatest(least((el->>'defense')::int, 99), 0);
      sp := greatest(least((el->>'speed')::int, 99), 0);
      st := greatest(least((el->>'stamina')::int, 99), 0);
      m := least(a, d, sp, st);
      total := total + m * 15;
    end loop;
    return total;
  end if;

  return 0;
end;
$$;

-- ---------------------------------------------------------------------------
-- submit_team_lineup_race(p_race_key text)  — race_key like r_power_2026-05-05 (UTC Monday id)
-- ---------------------------------------------------------------------------
create or replace function public.submit_team_lineup_race(p_race_key text)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  squad jsonb;
  players jsonb;
  mode text;
  sc int;
  tname text;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_race_key is null or length(trim(p_race_key)) < 8 then
    return jsonb_build_object('ok', false, 'error', 'bad_race_key');
  end if;

  if p_race_key like 'r_power_%' then
    mode := 'power';
  elsif p_race_key like 'r_speed_%' then
    mode := 'speed';
  elsif p_race_key like 'r_balance_%' then
    mode := 'balance';
  else
    return jsonb_build_object('ok', false, 'error', 'unknown_race');
  end if;

  select team_squad into squad from public.profiles where id = uid;
  if squad is null or squad->'players' is null then
    return jsonb_build_object('ok', false, 'error', 'no_squad_saved');
  end if;

  players := squad->'players';
  if jsonb_array_length(players) <> 6 then
    return jsonb_build_object('ok', false, 'error', 'bad_squad');
  end if;

  sc := public._lineup_race_score(players, mode);
  if sc <= 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_score');
  end if;

  tname := nullif(trim(squad->>'team_name'), '');
  if tname is null then
    tname := 'Squad';
  end if;

  insert into public.team_lineup_race_entries (
    race_key,
    user_id,
    score,
    team_name,
    submitted_at
  )
  values (p_race_key, uid, sc, tname, now())
  on conflict (race_key, user_id) do update
  set
    score = greatest(public.team_lineup_race_entries.score, excluded.score),
    team_name = excluded.team_name,
    submitted_at = excluded.submitted_at;

  return jsonb_build_object(
    'ok', true,
    'score', sc,
    'race_key', p_race_key
  );
end;
$$;

revoke all on function public.submit_team_lineup_race(text) from public;
grant execute on function public.submit_team_lineup_race(text) to authenticated;
