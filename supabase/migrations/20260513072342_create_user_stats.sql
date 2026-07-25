create table if not exists public.user_stats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  game_id text not null default 'overlap',
  current_streak integer not null default 0 check (current_streak >= 0),
  daily_win_count integer not null default 0 check (daily_win_count >= 0),
  daily_top3_count integer not null default 0 check (daily_top3_count >= 0),
  daily_top10_count integer not null default 0 check (daily_top10_count >= 0),
  last_play_date text,
  updated_at timestamptz not null default now()
);

create unique index if not exists user_stats_user_game_uidx
  on public.user_stats (user_id, game_id);

alter table public.user_stats enable row level security;

revoke insert, update, delete on public.user_stats from anon, authenticated;
grant select on public.user_stats to authenticated;

drop policy if exists "stats are owner readable" on public.user_stats;
create policy "stats are owner readable"
  on public.user_stats
  for select
  to authenticated
  using (auth.uid() = user_id);
