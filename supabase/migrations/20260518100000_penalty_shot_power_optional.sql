-- Penalty shootout no longer stores shot power; allow null for striker rows.
alter table public.penalty_round_picks
  drop constraint if exists penalty_round_picks_shot_power;

alter table public.penalty_round_picks
  add constraint penalty_round_picks_shot_power check (
    (pick_kind = 'dive' and power is null)
    or (
      pick_kind = 'shot'
      and (
        power is null
        or (
          power >= 0::double precision
          and power <= 1::double precision
        )
      )
    )
  );
