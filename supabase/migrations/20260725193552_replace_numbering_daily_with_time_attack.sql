-- Add server-verified Time Attack. The destructive removal of NUMBERING's
-- retired daily objects lives in the following cleanup migration so it can be
-- reviewed and approved independently from this deployment.

create table if not exists private.numbering_time_attack_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default clock_timestamp(),
  expires_at timestamptz not null,
  finished_at timestamptz,
  is_abandoned boolean not null default false,
  puzzle_index integer not null default 0 check (puzzle_index >= 0),
  current_digits text not null check (current_digits ~ '^[1-9]{4,6}$'),
  highest_number integer not null default 0 check (highest_number >= 0),
  total_score bigint not null default 0 check (total_score >= 0),
  highest_achieved_at timestamptz
);

create index if not exists numbering_time_attack_sessions_user_started_idx
on private.numbering_time_attack_sessions (user_id, started_at desc);

alter table private.numbering_time_attack_sessions enable row level security;
revoke all on table private.numbering_time_attack_sessions
from public, anon, authenticated;

create table if not exists private.numbering_time_attack_solutions (
  session_id uuid not null
    references private.numbering_time_attack_sessions(id) on delete cascade,
  puzzle_index integer not null check (puzzle_index >= 0),
  digits text not null check (digits ~ '^[1-9]{4,6}$'),
  expression_hash text not null check (expression_hash ~ '^[0-9a-f]{64}$'),
  score integer not null check (score >= 0),
  submitted_at timestamptz not null default clock_timestamp(),
  primary key (session_id, puzzle_index)
);

alter table private.numbering_time_attack_solutions enable row level security;
revoke all on table private.numbering_time_attack_solutions
from public, anon, authenticated;

create table if not exists public.numbering_time_attack_scores (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  highest_number integer not null check (highest_number >= 0),
  total_score bigint not null check (total_score >= 0),
  highest_achieved_at timestamptz not null,
  achieved_at timestamptz not null,
  updated_at timestamptz not null default clock_timestamp()
);

create index if not exists numbering_time_attack_scores_rank_idx
on public.numbering_time_attack_scores
  (highest_number desc, total_score desc, highest_achieved_at, user_id);

alter table public.numbering_time_attack_scores enable row level security;
drop policy if exists "Authenticated users can read time attack rankings"
on public.numbering_time_attack_scores;
create policy "Authenticated users can read time attack rankings"
on public.numbering_time_attack_scores
for select
to authenticated
using (true);

revoke all on table public.numbering_time_attack_scores
from public, anon, authenticated;
grant select on table public.numbering_time_attack_scores to authenticated;

create or replace function private._numbering_time_attack_digits(
  p_session_id uuid,
  p_puzzle_index integer,
  p_digit_count integer,
  p_excluded_digits text default null
)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select rules.digit_string
  from private.numbering_level_rules as rules
  where char_length(rules.digit_string) = p_digit_count
    and (
      p_excluded_digits is null
      or public._numbering_sorted_digits(rules.digit_string)
        <> public._numbering_sorted_digits(p_excluded_digits)
    )
  order by md5(
    p_session_id::text || ':' || p_puzzle_index::text || ':' || rules.level_id::text
  )
  limit 1;
$$;

revoke all on function private._numbering_time_attack_digits(uuid, integer, integer, text)
from public, anon, authenticated;

create or replace function private._numbering_upsert_time_attack_best(
  p_user_id uuid,
  p_highest_number integer,
  p_total_score bigint,
  p_highest_achieved_at timestamptz,
  p_achieved_at timestamptz
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.numbering_time_attack_scores (
    user_id,
    highest_number,
    total_score,
    highest_achieved_at,
    achieved_at,
    updated_at
  )
  values (
    p_user_id,
    p_highest_number,
    p_total_score,
    coalesce(p_highest_achieved_at, p_achieved_at),
    p_achieved_at,
    clock_timestamp()
  )
  on conflict (user_id) do update
  set highest_number = excluded.highest_number,
      total_score = excluded.total_score,
      highest_achieved_at = excluded.highest_achieved_at,
      achieved_at = excluded.achieved_at,
      updated_at = clock_timestamp()
  where excluded.highest_number > public.numbering_time_attack_scores.highest_number
     or (
       excluded.highest_number = public.numbering_time_attack_scores.highest_number
       and excluded.total_score > public.numbering_time_attack_scores.total_score
     )
     or (
       excluded.highest_number = public.numbering_time_attack_scores.highest_number
       and excluded.total_score = public.numbering_time_attack_scores.total_score
       and excluded.highest_achieved_at
         < public.numbering_time_attack_scores.highest_achieved_at
     );
$$;

revoke all on function private._numbering_upsert_time_attack_best(
  uuid, integer, bigint, timestamptz, timestamptz
) from public, anon, authenticated;

create or replace function public.start_numbering_time_attack()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_previous private.numbering_time_attack_sessions%rowtype;
  v_session_id uuid := gen_random_uuid();
  v_digits text;
  v_expires_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  for v_previous in
    select sessions.*
    from private.numbering_time_attack_sessions as sessions
    where sessions.user_id = v_user_id
      and sessions.finished_at is null
    for update
  loop
    if v_previous.expires_at <= v_now then
      perform private._numbering_upsert_time_attack_best(
        v_previous.user_id,
        v_previous.highest_number,
        v_previous.total_score,
        v_previous.highest_achieved_at,
        v_previous.expires_at
      );
      update private.numbering_time_attack_sessions
      set finished_at = v_now
      where id = v_previous.id;
    else
      update private.numbering_time_attack_sessions
      set finished_at = v_now,
          is_abandoned = true
      where id = v_previous.id;
    end if;
  end loop;

  v_digits := private._numbering_time_attack_digits(v_session_id, 0, 4, null);
  if v_digits is null then
    raise exception 'time attack puzzle catalog is empty';
  end if;
  v_expires_at := v_now + interval '180 seconds';

  insert into private.numbering_time_attack_sessions (
    id, user_id, started_at, expires_at, current_digits
  ) values (
    v_session_id, v_user_id, v_now, v_expires_at, v_digits
  );

  return jsonb_build_object(
    'session_id', v_session_id,
    'digits', v_digits,
    'puzzle_index', 0,
    'highest_number', 0,
    'total_score', 0,
    'expires_at', v_expires_at
  );
end;
$$;

create or replace function public.submit_numbering_time_attack_solution(
  p_session_id uuid,
  p_puzzle_index integer,
  p_expression text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_session private.numbering_time_attack_sessions%rowtype;
  v_expression text := replace(btrim(p_expression), ' ', '');
  v_sides text[];
  v_digits text;
  v_left bigint;
  v_right bigint;
  v_score integer;
  v_digest text;
  v_existing private.numbering_time_attack_solutions%rowtype;
  v_next_index integer;
  v_next_digit_count integer;
  v_next_digits text;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;
  if p_puzzle_index < 0 then
    raise exception 'invalid time attack puzzle index';
  end if;
  if char_length(v_expression) < 3
     or char_length(v_expression) > 129
     or v_expression !~ '^[0-9+\-×÷()=]+$'
     or char_length(v_expression) - char_length(replace(v_expression, '=', '')) <> 1 then
    raise exception 'invalid time attack expression';
  end if;

  select sessions.* into v_session
  from private.numbering_time_attack_sessions as sessions
  where sessions.id = p_session_id
    and sessions.user_id = v_user_id
  for update;

  if not found or v_session.finished_at is not null then
    raise exception 'time attack session is not active';
  end if;
  if v_now > v_session.expires_at then
    raise exception 'time attack session expired';
  end if;

  v_digest := encode(extensions.digest(v_expression, 'sha256'), 'hex');
  if p_puzzle_index <> v_session.puzzle_index then
    select solutions.* into v_existing
    from private.numbering_time_attack_solutions as solutions
    where solutions.session_id = p_session_id
      and solutions.puzzle_index = p_puzzle_index;

    if found and v_existing.expression_hash = v_digest then
      return jsonb_build_object(
        'session_id', v_session.id,
        'digits', v_session.current_digits,
        'puzzle_index', v_session.puzzle_index,
        'highest_number', v_session.highest_number,
        'total_score', v_session.total_score,
        'expires_at', v_session.expires_at,
        'is_idempotent', true
      );
    end if;
    raise exception 'invalid time attack puzzle index';
  end if;

  v_sides := string_to_array(v_expression, '=');
  if coalesce(array_length(v_sides, 1), 0) <> 2
     or v_sides[1] = ''
     or v_sides[2] = '' then
    raise exception 'invalid time attack expression';
  end if;

  v_digits := regexp_replace(v_expression, '[^0-9]', '', 'g');
  if public._numbering_sorted_digits(v_digits)
     <> public._numbering_sorted_digits(v_session.current_digits) then
    raise exception 'invalid time attack digits';
  end if;

  v_left := public._numbering_evaluate_expression(v_sides[1]);
  v_right := public._numbering_evaluate_expression(v_sides[2]);
  if v_left <> v_right or v_left < 0 or v_left > 99999999 then
    raise exception 'invalid time attack score';
  end if;
  v_score := v_left::integer;

  insert into private.numbering_time_attack_solutions (
    session_id, puzzle_index, digits, expression_hash, score, submitted_at
  ) values (
    v_session.id,
    v_session.puzzle_index,
    v_session.current_digits,
    v_digest,
    v_score,
    v_now
  );

  v_next_index := v_session.puzzle_index + 1;
  v_next_digit_count := case
    when v_next_index < 2 then 4
    when v_next_index < 4 then 5
    else 6
  end;
  v_next_digits := private._numbering_time_attack_digits(
    v_session.id,
    v_next_index,
    v_next_digit_count,
    v_session.current_digits
  );
  if v_next_digits is null then
    raise exception 'time attack puzzle catalog is empty';
  end if;

  update private.numbering_time_attack_sessions
  set puzzle_index = v_next_index,
      current_digits = v_next_digits,
      highest_number = greatest(highest_number, v_score),
      total_score = total_score + v_score,
      highest_achieved_at = case
        when v_score > highest_number then v_now
        else highest_achieved_at
      end
  where id = v_session.id
  returning * into v_session;

  return jsonb_build_object(
    'session_id', v_session.id,
    'digits', v_session.current_digits,
    'puzzle_index', v_session.puzzle_index,
    'highest_number', v_session.highest_number,
    'total_score', v_session.total_score,
    'expires_at', v_session.expires_at,
    'verified_score', v_score,
    'is_idempotent', false
  );
exception
  when numeric_value_out_of_range or division_by_zero then
    raise exception 'invalid time attack expression';
end;
$$;

create or replace function public.finish_numbering_time_attack(
  p_session_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_session private.numbering_time_attack_sessions%rowtype;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select sessions.* into v_session
  from private.numbering_time_attack_sessions as sessions
  where sessions.id = p_session_id
    and sessions.user_id = v_user_id
  for update;

  if not found or v_session.is_abandoned then
    raise exception 'time attack session not found';
  end if;
  if v_session.finished_at is null and v_now < v_session.expires_at - interval '1 second' then
    raise exception 'time attack session is still active';
  end if;

  if v_session.finished_at is null then
    update private.numbering_time_attack_sessions
    set finished_at = v_now
    where id = v_session.id;

    perform private._numbering_upsert_time_attack_best(
      v_session.user_id,
      v_session.highest_number,
      v_session.total_score,
      v_session.highest_achieved_at,
      v_session.expires_at
    );
  end if;

  return jsonb_build_object(
    'session_id', v_session.id,
    'highest_number', v_session.highest_number,
    'total_score', v_session.total_score,
    'finished_at', coalesce(v_session.finished_at, v_now)
  );
end;
$$;

create or replace function public.get_numbering_time_attack_leaderboard(
  p_limit integer default 100
)
returns table (
  user_id uuid,
  nickname text,
  avatar_url text,
  highest_number integer,
  total_score bigint,
  highest_achieved_at timestamptz,
  achieved_at timestamptz,
  rank bigint,
  is_me boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  with ranked as (
    select
      scores.user_id,
      coalesce(profiles.nickname, 'Player') as nickname,
      profiles.avatar_url,
      scores.highest_number,
      scores.total_score,
      scores.highest_achieved_at,
      scores.achieved_at,
      row_number() over (
        order by
          scores.highest_number desc,
          scores.total_score desc,
          scores.highest_achieved_at,
          scores.user_id
      ) as rank
    from public.numbering_time_attack_scores as scores
    join public.profiles as profiles on profiles.id = scores.user_id
  )
  select
    ranked.user_id,
    ranked.nickname,
    ranked.avatar_url,
    ranked.highest_number,
    ranked.total_score,
    ranked.highest_achieved_at,
    ranked.achieved_at,
    ranked.rank,
    ranked.user_id = auth.uid() as is_me
  from ranked
  where ranked.rank <= greatest(1, least(coalesce(p_limit, 100), 100))
     or ranked.user_id = auth.uid()
  order by ranked.rank;
$$;

revoke all on function public.start_numbering_time_attack()
from public, anon;
revoke all on function public.submit_numbering_time_attack_solution(uuid, integer, text)
from public, anon;
revoke all on function public.finish_numbering_time_attack(uuid)
from public, anon;
revoke all on function public.get_numbering_time_attack_leaderboard(integer)
from public, anon;

grant execute on function public.start_numbering_time_attack()
to authenticated;
grant execute on function public.submit_numbering_time_attack_solution(uuid, integer, text)
to authenticated;
grant execute on function public.finish_numbering_time_attack(uuid)
to authenticated;
grant execute on function public.get_numbering_time_attack_leaderboard(integer)
to authenticated;
