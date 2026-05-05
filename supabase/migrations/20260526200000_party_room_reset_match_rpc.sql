-- Clear party room scores for a new run only after every joined member finished
-- (5 round_times or timed_out). Prevents one device from resetting while others play.

create or replace function public.party_game_room_reset_match (p_room uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  joined_ids uuid[];
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  select coalesce(array_agg(m.user_id order by m.user_id), array[]::uuid[])
  into joined_ids
  from public.party_game_room_members m
  where m.room_id = p_room
    and m.status = 'joined';

  if joined_ids is null
     or array_length(joined_ids, 1) is null
     or array_length(joined_ids, 1) < 2 then
    raise exception 'room needs at least 2 joined players';
  end if;

  if not (uid = any(joined_ids)) then
    raise exception 'not a room member';
  end if;

  if exists (
    select 1
    from unnest(joined_ids) as jid
    where not exists (
      select 1
      from public.party_game_room_scores s
      where s.room_id = p_room
        and s.user_id = jid
        and (
          coalesce((s.meta->>'timed_out')::text, '') in ('true', 't', '1')
          or jsonb_array_length(coalesce(s.meta->'round_times', '[]'::jsonb)) >= 5
        )
    )
  ) then
    raise exception 'all_players_must_finish';
  end if;

  delete from public.party_game_room_scores
  where room_id = p_room;
end;
$$;

grant execute on function public.party_game_room_reset_match (uuid) to authenticated;

revoke all on function public.party_game_room_reset_match (uuid) from public;
