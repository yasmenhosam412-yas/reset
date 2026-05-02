-- Ready flags for match lobby (both sides must mark ready in app)
alter table public.game_challenges
  add column if not exists from_ready boolean not null default false,
  add column if not exists to_ready boolean not null default false;
