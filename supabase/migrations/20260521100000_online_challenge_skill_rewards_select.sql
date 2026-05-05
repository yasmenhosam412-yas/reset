-- Let challenge participants read who won (for profile / history UI).

drop policy if exists "online_challenge_skill_rewards_select_participant"
  on public.online_challenge_skill_rewards;

create policy "online_challenge_skill_rewards_select_participant"
  on public.online_challenge_skill_rewards for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_challenges gc
      where gc.id = challenge_id
        and (gc.from_user_id = auth.uid() or gc.to_user_id = auth.uid())
    )
  );
