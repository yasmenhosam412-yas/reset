-- Broadcast row changes to clients (RLS on game_challenges still filters who receives events)
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'game_challenges'
  ) then
    alter publication supabase_realtime add table public.game_challenges;
  end if;
end $$;

alter table public.game_challenges replica identity full;
