-- Solo daily friendly vs a deterministic "academy" side: Power score compare, skill points only (no roster stat swings).

create table if not exists public.team_academy_scrim_daily (
  user_id uuid not null references public.profiles (id) on delete cascade,
  claim_day date not null,
  primary key (user_id, claim_day)
);

alter table public.team_academy_scrim_daily enable row level security;

create or replace function public.claim_team_academy_scrim ()
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  tz_day date := (timezone('utc', now()))::date;
  squad jsonb;
  pl jsonb;
  sc_me int;
  h_name int;
  h_score int;
  bot_i int;
  bot_name text;
  names text[] := array[
    'Neon Gate Reserves',
    'Harbor United B',
    'Riverside Athletic II',
    'Midnight Academy',
    'Cobalt City Colts'
  ];
  bot_score int;
  my_out text;
  pts int;
  new_bal int;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if exists (
    select 1
    from public.team_academy_scrim_daily d
    where d.user_id = uid
      and d.claim_day = tz_day
  ) then
    return jsonb_build_object('ok', false, 'error', 'already_scrimmed');
  end if;

  select team_squad into squad
  from public.profiles
  where id = uid;

  if squad is null or squad->'players' is null then
    return jsonb_build_object('ok', false, 'error', 'no_squad_saved');
  end if;

  pl := squad->'players';
  if jsonb_array_length(pl) <> 6 then
    return jsonb_build_object('ok', false, 'error', 'bad_squad');
  end if;

  sc_me := public._lineup_race_score(pl, 'power');

  h_name := abs(hashtext(uid::text || tz_day::text || 'academy_nm'));
  h_score := abs(hashtext(uid::text || tz_day::text || 'academy_pw'));
  bot_i := 1 + mod(h_name, array_length(names, 1));
  bot_name := names[bot_i];
  bot_score := 340 + mod(h_score, 221);

  if sc_me > bot_score then
    my_out := 'win';
    pts := 18;
  elsif sc_me < bot_score then
    my_out := 'lose';
    pts := 8;
  else
    my_out := 'tie';
    pts := 12;
  end if;

  update public.profiles
  set team_skill_points = team_skill_points + pts
  where id = uid;

  insert into public.team_academy_scrim_daily (user_id, claim_day)
  values (uid, tz_day);

  select team_skill_points into new_bal
  from public.profiles
  where id = uid;

  return jsonb_build_object(
    'ok', true,
    'outcome', my_out,
    'my_score', sc_me,
    'opponent_score', bot_score,
    'opponent_name', bot_name,
    'points_awarded', pts,
    'balance', new_bal
  );
end;
$$;

revoke all on function public.claim_team_academy_scrim () from public;
grant execute on function public.claim_team_academy_scrim () to authenticated;
