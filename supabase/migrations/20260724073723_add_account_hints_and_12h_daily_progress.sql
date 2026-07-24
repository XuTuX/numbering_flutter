-- Account-backed hint balances, resumable Numbering challenge state, and
-- two fixed Numbering challenge windows per KST day (00:00 and 12:00).

create table if not exists public.numbering_user_resources (
  user_id uuid primary key references auth.users(id) on delete cascade,
  hint_count integer not null default 20 check (hint_count between 0 and 9999),
  last_attendance_date date,
  is_initialized boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.numbering_user_resources enable row level security;

drop policy if exists "numbering resources are owner readable"
on public.numbering_user_resources;
create policy "numbering resources are owner readable"
on public.numbering_user_resources
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.numbering_user_resources from public, anon;
grant select on table public.numbering_user_resources to authenticated;

create or replace function public.sync_my_numbering_hints(
  p_local_hint_count integer default 20,
  p_local_last_attendance_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_today date := timezone('Asia/Seoul', now())::date;
  v_count integer;
  v_last_date date;
  v_initialized boolean;
  v_awarded boolean := false;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  insert into public.numbering_user_resources (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select hint_count, last_attendance_date, is_initialized
  into v_count, v_last_date, v_initialized
  from public.numbering_user_resources
  where user_id = v_user_id
  for update;

  if not v_initialized then
    v_count := greatest(0, least(coalesce(p_local_hint_count, 20), 9999));
    v_last_date := coalesce(p_local_last_attendance_date, v_today);
    update public.numbering_user_resources
    set hint_count = v_count,
        last_attendance_date = v_last_date,
        is_initialized = true,
        updated_at = now()
    where user_id = v_user_id;
  end if;

  if v_last_date is null or v_last_date < v_today then
    v_count := least(v_count + 3, 9999);
    v_last_date := v_today;
    v_awarded := true;
    update public.numbering_user_resources
    set hint_count = v_count,
        last_attendance_date = v_last_date,
        updated_at = now()
    where user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'hint_count', v_count,
    'last_attendance_date', v_last_date,
    'attendance_awarded', v_awarded
  );
end;
$$;

create or replace function public.consume_my_numbering_hint()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_count integer;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select hint_count into v_count
  from public.numbering_user_resources
  where user_id = v_user_id and is_initialized
  for update;

  if v_count is null or v_count <= 0 then
    return jsonb_build_object('used', false, 'hint_count', coalesce(v_count, 0));
  end if;

  v_count := v_count - 1;
  update public.numbering_user_resources
  set hint_count = v_count, updated_at = now()
  where user_id = v_user_id;

  return jsonb_build_object('used', true, 'hint_count', v_count);
end;
$$;

create or replace function public.add_my_numbering_hints(p_amount integer)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_count integer;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 100 then
    raise exception 'invalid hint amount' using errcode = '22023';
  end if;

  update public.numbering_user_resources
  set hint_count = least(hint_count + p_amount, 9999), updated_at = now()
  where user_id = v_user_id and is_initialized
  returning hint_count into v_count;

  if v_count is null then
    raise exception 'hint state is not initialized' using errcode = '55000';
  end if;
  return v_count;
end;
$$;

revoke all on function public.sync_my_numbering_hints(integer, date) from public, anon;
revoke all on function public.consume_my_numbering_hint() from public, anon;
revoke all on function public.add_my_numbering_hints(integer)
from public, anon, authenticated;
grant execute on function public.sync_my_numbering_hints(integer, date) to authenticated;
grant execute on function public.consume_my_numbering_hint() to authenticated;

create table if not exists public.numbering_daily_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  period_key text not null
    check (period_key ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}-(00|12)$'),
  seed integer not null,
  state jsonb not null default '{}'::jsonb
    check (
      jsonb_typeof(state) = 'object'
      and octet_length(state::text) <= 4096
    ),
  updated_at timestamptz not null default now(),
  primary key (user_id, period_key)
);

alter table public.numbering_daily_progress enable row level security;

drop policy if exists "numbering progress is owner readable"
on public.numbering_daily_progress;
create policy "numbering progress is owner readable"
on public.numbering_daily_progress
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "numbering progress is owner insertable"
on public.numbering_daily_progress;
create policy "numbering progress is owner insertable"
on public.numbering_daily_progress
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "numbering progress is owner updatable"
on public.numbering_daily_progress;
create policy "numbering progress is owner updatable"
on public.numbering_daily_progress
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "numbering progress is owner deletable"
on public.numbering_daily_progress;
create policy "numbering progress is owner deletable"
on public.numbering_daily_progress
for delete
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.numbering_daily_progress from public, anon;
grant select, insert, update, delete
on table public.numbering_daily_progress to authenticated;

create or replace function public._numbering_challenge_period_key(
  p_at timestamptz default now()
)
returns text
language sql
stable
set search_path = ''
as $$
  select to_char(timezone('Asia/Seoul', p_at), 'YYYY-MM-DD')
    || case
         when extract(hour from timezone('Asia/Seoul', p_at)) < 12 then '-00'
         else '-12'
       end;
$$;

create or replace function public.get_daily_challenge(p_game_id text)
returns table(date_key text, seed integer, has_used_entry boolean, my_score integer)
language sql
stable
security definer
set search_path = 'public'
as $$
  with current_period as (
    select case
      when p_game_id = 'numbering' then public._numbering_challenge_period_key(now())
      else to_char(timezone('Asia/Seoul', now()), 'YYYY-MM-DD')
    end as date_key
  ),
  my_attempt as (
    select 1
    from public.daily_attempts da
    cross join current_period cp
    where da.user_id = auth.uid()
      and da.game_id = p_game_id
      and da.date_key = cp.date_key
    limit 1
  ),
  my_entry as (
    select ds.score
    from public.daily_scores ds
    cross join current_period cp
    where ds.user_id = auth.uid()
      and ds.game_id = p_game_id
      and ds.date_key = cp.date_key
    limit 1
  )
  select
    cp.date_key,
    public.get_daily_challenge_seed(p_game_id, cp.date_key),
    exists(select 1 from my_attempt) or exists(select 1 from my_entry),
    (select score from my_entry limit 1)
  from current_period cp;
$$;

create or replace function public.claim_daily_challenge_entry(p_game_id text)
returns table(date_key text, seed integer, has_used_entry boolean, my_score integer)
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_date_key text := case
    when p_game_id = 'numbering' then public._numbering_challenge_period_key(now())
    else to_char(timezone('Asia/Seoul', now()), 'YYYY-MM-DD')
  end;
  v_seed integer := public.get_daily_challenge_seed(p_game_id, v_date_key);
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  if p_game_id is null or btrim(p_game_id) = '' then
    raise exception 'game_id is required';
  end if;

  if exists (
    select 1 from public.daily_attempts da
    where da.user_id = v_user_id and da.game_id = p_game_id
      and da.date_key = v_date_key
  ) or exists (
    select 1 from public.daily_scores ds
    where ds.user_id = v_user_id and ds.game_id = p_game_id
      and ds.date_key = v_date_key
  ) then
    raise exception 'Daily challenge already used';
  end if;

  insert into public.daily_attempts (user_id, game_id, date_key, seed)
  values (v_user_id, p_game_id, v_date_key, v_seed);

  return query select v_date_key, v_seed, true, null::integer;
end;
$$;

create or replace function public.submit_numbering_daily_result(
  p_seed integer,
  p_expression text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_period_key text := public._numbering_challenge_period_key(now());
  v_expected_seed integer;
  v_expected_digits text;
  v_expression text := regexp_replace(replace(replace(btrim(p_expression), '*', '×'), '/', '÷'), '\s+', '', 'g');
  v_submitted_digits text;
  v_sides text[];
  v_left bigint;
  v_right bigint;
  v_score integer;
  v_digest text;
  v_existing_score integer;
  v_existing_seed integer;
  v_existing_digest text;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if not exists (select 1 from public.games where id = 'numbering') then
    raise exception 'invalid game';
  end if;
  v_expected_seed := public.get_daily_challenge_seed('numbering', v_period_key);
  if p_seed is distinct from v_expected_seed then raise exception 'invalid daily seed'; end if;
  if not exists (
    select 1 from public.daily_attempts
    where user_id = v_user_id and game_id = 'numbering'
      and date_key = v_period_key and seed = v_expected_seed
  ) then
    raise exception 'daily entry not claimed';
  end if;
  if v_expression is null or char_length(v_expression) > 96
     or v_expression !~ '^[0-9+\-×÷=()]+$'
     or char_length(v_expression) - char_length(replace(v_expression, '=', '')) <> 1 then
    raise exception 'invalid daily expression';
  end if;

  v_expected_digits := public._numbering_daily_digits(v_expected_seed);
  v_submitted_digits := regexp_replace(v_expression, '[^0-9]', '', 'g');
  if v_submitted_digits <> v_expected_digits then
    raise exception 'daily expression digits do not match the seed';
  end if;

  v_sides := string_to_array(v_expression, '=');
  if coalesce(v_sides[1], '') = '' or coalesce(v_sides[2], '') = '' then
    raise exception 'invalid daily equation';
  end if;
  v_left := public._numbering_evaluate_expression(v_sides[1]);
  v_right := public._numbering_evaluate_expression(v_sides[2]);
  if v_left <> v_right or v_left < 0 or v_left > 99999999 then
    raise exception 'invalid daily score';
  end if;
  v_score := v_left::integer;
  v_digest := encode(digest(v_expression, 'sha256'), 'hex');

  perform pg_advisory_xact_lock(
    hashtextextended(v_user_id::text || ':numbering:' || v_period_key, 0)
  );
  select score, seed, summary_json ->> 'expression_sha256'
  into v_existing_score, v_existing_seed, v_existing_digest
  from public.daily_scores
  where user_id = v_user_id and game_id = 'numbering'
    and date_key = v_period_key;

  if found then
    if v_existing_seed is distinct from v_expected_seed
       or v_existing_score is distinct from v_score
       or v_existing_digest is distinct from v_digest then
      raise exception 'daily score already submitted';
    end if;
    return jsonb_build_object(
      'verified_score', v_existing_score,
      'previous_best', v_existing_score,
      'current_best', v_existing_score,
      'is_new_best', false,
      'is_idempotent', true,
      'date_key', v_period_key
    );
  end if;

  perform set_config('app.numbering_verified_write', 'on', true);
  insert into public.daily_scores (
    user_id, game_id, date_key, seed, score, replay_code, summary_json
  ) values (
    v_user_id,
    'numbering',
    v_period_key,
    v_expected_seed,
    v_score,
    null,
    jsonb_build_object(
      'version', 3,
      'expression_sha256', v_digest,
      'verified_digits', v_expected_digits,
      'submission_rule', 'ordered_equality_12h_entry'
    )
  );
  delete from public.numbering_daily_progress
  where user_id = v_user_id and period_key = v_period_key;

  return jsonb_build_object(
    'verified_score', v_score,
    'previous_best', null,
    'current_best', v_score,
    'is_new_best', true,
    'is_idempotent', false,
    'date_key', v_period_key
  );
end;
$$;

revoke all on function public._numbering_challenge_period_key(timestamptz)
from public, anon, authenticated;
revoke all on function public.submit_numbering_daily_result(integer, text)
from public, anon;
grant execute on function public.submit_numbering_daily_result(integer, text)
to authenticated;

notify pgrst, 'reload schema';
