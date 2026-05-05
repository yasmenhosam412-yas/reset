-- Allow five dive / shot directions: far left (-2) … far right (2).

do $$
declare
  r record;
begin
  for r in
    select c.conname as name
    from pg_constraint c
    join pg_class t on c.conrelid = t.oid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'penalty_round_picks'
      and c.contype = 'c'
      and pg_get_constraintdef(c.oid) like '%direction%'
  loop
    execute format(
      'alter table public.penalty_round_picks drop constraint %I',
      r.name
    );
  end loop;
end $$;

alter table public.penalty_round_picks
  add constraint penalty_round_picks_direction_lane_check
  check (direction >= -2 and direction <= 2);
