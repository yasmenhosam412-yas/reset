-- RPS / fantasy previously left game_challenges as `accepted` after the bout
-- ended (only session rows + skill rewards changed). Align with penalty cleanup.

update public.game_challenges gc
set
  status = 'completed',
  from_ready = false,
  to_ready = false,
  completed_at = coalesce(
    gc.completed_at,
    rp.updated_at,
    timezone('utc', now())
  )
from public.rps_sessions rp
where rp.challenge_id = gc.id
  and rp.status = 'done'
  and gc.game_id = 2
  and gc.status is distinct from 'completed';

update public.game_challenges gc
set
  status = 'completed',
  from_ready = false,
  to_ready = false,
  completed_at = coalesce(
    gc.completed_at,
    s.updated_at,
    timezone('utc', now())
  )
from public.fantasy_duel_sessions s
where s.challenge_id = gc.id
  and s.match_complete = true
  and gc.game_id = 3
  and gc.status is distinct from 'completed';

create or replace function public.trg_rps_complete_game_challenge()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  if new.status = 'done' and (old.status is distinct from new.status) then
    update public.game_challenges gc
    set
      status = 'completed',
      from_ready = false,
      to_ready = false,
      completed_at = coalesce(gc.completed_at, timezone('utc', now()))
    where gc.id = new.challenge_id
      and gc.game_id = 2
      and gc.status is distinct from 'completed';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_rps_complete_game_challenge on public.rps_sessions;
create trigger trg_rps_complete_game_challenge
  after update of status on public.rps_sessions
  for each row
  execute procedure public.trg_rps_complete_game_challenge();

create or replace function public.trg_fantasy_complete_game_challenge()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  if new.match_complete = true
     and (old.match_complete is distinct from new.match_complete) then
    update public.game_challenges gc
    set
      status = 'completed',
      from_ready = false,
      to_ready = false,
      completed_at = coalesce(gc.completed_at, timezone('utc', now()))
    where gc.id = new.challenge_id
      and gc.game_id = 3
      and gc.status is distinct from 'completed';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_fantasy_complete_game_challenge
  on public.fantasy_duel_sessions;
create trigger trg_fantasy_complete_game_challenge
  after update of match_complete on public.fantasy_duel_sessions
  for each row
  execute procedure public.trg_fantasy_complete_game_challenge();
