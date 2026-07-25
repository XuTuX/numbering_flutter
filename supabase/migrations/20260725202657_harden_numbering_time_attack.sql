-- Harden server-verified Time Attack against concurrent starts, client clock
-- drift, and sessions that expire while the app is not running.

create extension if not exists pg_cron with schema pg_catalog;

create or replace function private._numbering_finalize_expired_time_attacks(
  p_limit integer default 500
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_session private.numbering_time_attack_sessions%rowtype;
  v_finalized integer := 0;
begin
  for v_session in
    select sessions.*
    from private.numbering_time_attack_sessions as sessions
    where sessions.finished_at is null
      and not sessions.is_abandoned
      and sessions.expires_at <= v_now
    order by sessions.expires_at, sessions.id
    for update skip locked
    limit greatest(1, least(coalesce(p_limit, 500), 5000))
  loop
    perform private._numbering_upsert_time_attack_best(
      v_session.user_id,
      v_session.highest_number,
      v_session.total_score,
      v_session.highest_achieved_at,
      v_session.expires_at
    );

    update private.numbering_time_attack_sessions
    set finished_at = v_session.expires_at
    where id = v_session.id
      and finished_at is null;

    v_finalized := v_finalized + 1;
  end loop;

  return v_finalized;
end;
$$;

revoke all on function private._numbering_finalize_expired_time_attacks(integer)
from public, anon, authenticated;

-- Drain already-expired rows before enforcing one unfinished session per user.
do $$
declare
  v_finalized integer;
begin
  loop
    v_finalized := private._numbering_finalize_expired_time_attacks(5000);
    exit when v_finalized < 5000;
  end loop;
end;
$$;

with duplicate_sessions as (
  select
    sessions.id,
    row_number() over (
      partition by sessions.user_id
      order by sessions.started_at desc, sessions.id desc
    ) as duplicate_order
  from private.numbering_time_attack_sessions as sessions
  where sessions.finished_at is null
)
update private.numbering_time_attack_sessions as sessions
set finished_at = clock_timestamp(),
    is_abandoned = true
from duplicate_sessions
where sessions.id = duplicate_sessions.id
  and duplicate_sessions.duplicate_order > 1;

create unique index if not exists numbering_time_attack_one_active_session_idx
on private.numbering_time_attack_sessions (user_id)
where finished_at is null;

create or replace function public.start_numbering_time_attack()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz;
  v_recent_starts integer;
  v_previous private.numbering_time_attack_sessions%rowtype;
  v_session_id uuid := gen_random_uuid();
  v_digits text;
  v_expires_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  -- Serialize all starts for the same user before inspecting open sessions.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_user_id::text, 74969413)
  );
  v_now := clock_timestamp();

  select count(*)::integer into v_recent_starts
  from private.numbering_time_attack_sessions as sessions
  where sessions.user_id = v_user_id
    and sessions.started_at >= v_now - interval '1 minute';

  if v_recent_starts >= 10 then
    raise exception 'time attack start rate limit exceeded';
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
      set finished_at = v_previous.expires_at
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
    'expires_at', v_expires_at,
    'server_now', v_now,
    'remaining_ms', 180000
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
  v_expression text := replace(btrim(coalesce(p_expression, '')), ' ', '');
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
  v_remaining_ms bigint;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;
  if p_puzzle_index is null or p_puzzle_index < 0 then
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
  if v_now >= v_session.expires_at then
    raise exception 'time attack session expired';
  end if;

  v_remaining_ms := greatest(
    0,
    (extract(epoch from (v_session.expires_at - v_now)) * 1000)::bigint
  );
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
        'server_now', v_now,
        'remaining_ms', v_remaining_ms,
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

  v_remaining_ms := greatest(
    0,
    (extract(epoch from (v_session.expires_at - v_now)) * 1000)::bigint
  );

  return jsonb_build_object(
    'session_id', v_session.id,
    'digits', v_session.current_digits,
    'puzzle_index', v_session.puzzle_index,
    'highest_number', v_session.highest_number,
    'total_score', v_session.total_score,
    'expires_at', v_session.expires_at,
    'server_now', v_now,
    'remaining_ms', v_remaining_ms,
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
  if v_session.finished_at is null and v_now < v_session.expires_at then
    raise exception 'time attack session is still active';
  end if;

  if v_session.finished_at is null then
    update private.numbering_time_attack_sessions
    set finished_at = v_session.expires_at
    where id = v_session.id;

    perform private._numbering_upsert_time_attack_best(
      v_session.user_id,
      v_session.highest_number,
      v_session.total_score,
      v_session.highest_achieved_at,
      v_session.expires_at
    );
    v_session.finished_at := v_session.expires_at;
  end if;

  return jsonb_build_object(
    'session_id', v_session.id,
    'highest_number', v_session.highest_number,
    'total_score', v_session.total_score,
    'finished_at', v_session.finished_at,
    'server_now', v_now
  );
end;
$$;

revoke all on function public.start_numbering_time_attack()
from public, anon;
revoke all on function public.submit_numbering_time_attack_solution(uuid, integer, text)
from public, anon;
revoke all on function public.finish_numbering_time_attack(uuid)
from public, anon;

grant execute on function public.start_numbering_time_attack()
to authenticated;
grant execute on function public.submit_numbering_time_attack_solution(uuid, integer, text)
to authenticated;
grant execute on function public.finish_numbering_time_attack(uuid)
to authenticated;

do $$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobs.jobid
    from cron.job as jobs
    where jobs.jobname = 'finalize-numbering-time-attack'
  loop
    perform cron.unschedule(v_job_id);
  end loop;

  perform cron.schedule(
    'finalize-numbering-time-attack',
    '* * * * *',
    'select private._numbering_finalize_expired_time_attacks(500);'
  );
end;
$$;
