-- Optional: friends with accepts_match_invites = false do not receive new online game challenges.

alter table public.profiles
  add column if not exists accepts_match_invites boolean not null default true;

comment on column public.profiles.accepts_match_invites is
  'When false, other users cannot insert game_challenges targeting this profile.';

create or replace function public.enforce_game_challenge_recipient_accepts_invites ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  ok boolean;
begin
  ok := coalesce(
    (
      select p.accepts_match_invites
      from public.profiles p
      where p.id = NEW.to_user_id
    ),
    true
  );
  if not ok then
    raise exception 'recipient_does_not_accept_invites'
      using errcode = 'P0001';
  end if;
  return NEW;
end;
$$;

drop trigger if exists game_challenges_enforce_recipient_invites on public.game_challenges;

create trigger game_challenges_enforce_recipient_invites
  before insert on public.game_challenges
  for each row
  execute procedure public.enforce_game_challenge_recipient_accepts_invites ();

revoke all on function public.enforce_game_challenge_recipient_accepts_invites () from public;
