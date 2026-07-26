-- Persist Numbering arcade level progress per account. The sync RPC merges
-- records monotonically so an older device cannot overwrite a better result.

create table if not exists public.numbering_arcade_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  level_id integer not null check (level_id between 1 and 10000),
  cleared boolean not null default false,
  best_score bigint,
  stars integer not null default 0 check (stars between 0 and 3),
  perfect boolean not null default false,
  used_hints integer not null default 0 check (used_hints between 0 and 3),
  updated_at timestamptz not null default now(),
  primary key (user_id, level_id)
);

alter table public.numbering_arcade_progress enable row level security;

drop policy if exists "numbering arcade progress is owner readable"
on public.numbering_arcade_progress;
create policy "numbering arcade progress is owner readable"
on public.numbering_arcade_progress
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "numbering arcade progress is owner insertable"
on public.numbering_arcade_progress;
create policy "numbering arcade progress is owner insertable"
on public.numbering_arcade_progress
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "numbering arcade progress is owner updatable"
on public.numbering_arcade_progress;
create policy "numbering arcade progress is owner updatable"
on public.numbering_arcade_progress
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on table public.numbering_arcade_progress from public, anon;
grant select, insert, update
on table public.numbering_arcade_progress to authenticated;

create or replace function public.sync_my_numbering_arcade_progress(
  p_progress jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_item jsonb;
  v_level_id integer;
  v_cleared boolean;
  v_best_score bigint;
  v_stars integer;
  v_perfect boolean;
  v_used_hints integer;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_progress is null or jsonb_typeof(p_progress) <> 'array' then
    raise exception 'progress must be an array' using errcode = '22023';
  end if;
  if jsonb_array_length(p_progress) > 10000
     or octet_length(p_progress::text) > 262144 then
    raise exception 'progress payload is too large' using errcode = '22023';
  end if;

  for v_item in select value from jsonb_array_elements(p_progress)
  loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'progress entry must be an object' using errcode = '22023';
    end if;

    v_level_id := (v_item ->> 'levelId')::integer;
    v_cleared := coalesce((v_item ->> 'cleared')::boolean, false);
    v_best_score := (v_item ->> 'bestScore')::bigint;
    v_stars := coalesce((v_item ->> 'stars')::integer, 0);
    v_perfect := coalesce((v_item ->> 'perfect')::boolean, false);
    v_used_hints := coalesce((v_item ->> 'usedHints')::integer, 0);

    if v_level_id not between 1 and 10000
       or v_stars not between 0 and 3
       or v_used_hints not between 0 and 3 then
      raise exception 'invalid arcade progress entry' using errcode = '22023';
    end if;

    insert into public.numbering_arcade_progress as stored (
      user_id,
      level_id,
      cleared,
      best_score,
      stars,
      perfect,
      used_hints,
      updated_at
    ) values (
      v_user_id,
      v_level_id,
      v_cleared,
      v_best_score,
      v_stars,
      v_perfect,
      v_used_hints,
      now()
    )
    on conflict (user_id, level_id) do update
    set cleared = stored.cleared or excluded.cleared,
        best_score = case
          when stored.best_score is null then excluded.best_score
          when excluded.best_score is null then stored.best_score
          else greatest(stored.best_score, excluded.best_score)
        end,
        stars = case
          when stored.best_score is null
               or excluded.best_score > stored.best_score
            then excluded.stars
          when excluded.best_score = stored.best_score
            then greatest(stored.stars, excluded.stars)
          else stored.stars
        end,
        perfect = stored.perfect or excluded.perfect,
        used_hints = case
          when stored.best_score is null
               or excluded.best_score > stored.best_score
            then excluded.used_hints
          when excluded.best_score = stored.best_score
            then least(stored.used_hints, excluded.used_hints)
          else stored.used_hints
        end,
        updated_at = now();
  end loop;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'levelId', level_id,
        'cleared', cleared,
        'bestScore', best_score,
        'stars', stars,
        'perfect', perfect,
        'usedHints', used_hints
      ) order by level_id
    ),
    '[]'::jsonb
  )
  into v_result
  from public.numbering_arcade_progress
  where user_id = v_user_id;

  return v_result;
end;
$$;

revoke all on function public.sync_my_numbering_arcade_progress(jsonb)
from public, anon;
grant execute on function public.sync_my_numbering_arcade_progress(jsonb)
to authenticated;
