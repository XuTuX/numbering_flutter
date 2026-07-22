-- Make the official daily challenge follow Numbering's core rule:
-- preserve digit order, build one valid equality, and rank its shared value.

create or replace function public._numbering_daily_digits(p_seed integer)
returns text
language plpgsql
immutable
strict
set search_path = public
as $$
declare
  v_modulus constant bigint := 2147483647;
  v_state bigint := p_seed::bigint % v_modulus;
  v_left integer[] := array[]::integer[];
  v_right integer[];
  v_index integer;
  v_offset integer;
  v_source_start integer;
  v_destination_start integer;
  v_source integer;
  v_destination integer;
  v_maximum_transfer integer;
  v_amount integer;
  v_digits text := '';
begin
  if v_state <= 0 then v_state := v_state + v_modulus - 1; end if;

  for v_index in 1..4 loop
    v_state := (v_state * 48271) % v_modulus;
    v_left := array_append(v_left, (1 + (v_state % 9))::integer);
  end loop;
  v_right := v_left;

  v_state := (v_state * 48271) % v_modulus;
  v_source_start := (v_state % 4)::integer + 1;
  for v_offset in 0..3 loop
    v_index := ((v_source_start - 1 + v_offset) % 4) + 1;
    if v_right[v_index] > 1 then
      v_source := v_index;
      exit;
    end if;
  end loop;

  if v_source is not null then
    v_state := (v_state * 48271) % v_modulus;
    v_destination_start := (v_state % 4)::integer + 1;
    for v_offset in 0..3 loop
      v_index := ((v_destination_start - 1 + v_offset) % 4) + 1;
      if v_index <> v_source and v_right[v_index] < 9 then
        v_destination := v_index;
        exit;
      end if;
    end loop;

    if v_destination is not null then
      v_maximum_transfer := least(
        v_right[v_source] - 1,
        9 - v_right[v_destination]
      );
      v_state := (v_state * 48271) % v_modulus;
      v_amount := 1 + (v_state % v_maximum_transfer)::integer;
      v_right[v_source] := v_right[v_source] - v_amount;
      v_right[v_destination] := v_right[v_destination] + v_amount;
    end if;
  end if;

  foreach v_index in array v_left || v_right loop
    v_digits := v_digits || v_index::text;
  end loop;
  return v_digits;
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
  v_today text := to_char(timezone('Asia/Seoul', now()), 'YYYY-MM-DD');
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
  v_rank integer;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if not exists (select 1 from public.games where id = 'numbering') then
    raise exception 'invalid game';
  end if;
  v_expected_seed := public.get_daily_challenge_seed('numbering', v_today);
  if p_seed is distinct from v_expected_seed then raise exception 'invalid daily seed'; end if;
  if not exists (
    select 1 from public.daily_attempts
    where user_id = v_user_id and game_id = 'numbering'
      and date_key = v_today and seed = v_expected_seed
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

  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':numbering:' || v_today, 0));
  select score, seed, summary_json ->> 'expression_sha256'
  into v_existing_score, v_existing_seed, v_existing_digest
  from public.daily_scores
  where user_id = v_user_id and game_id = 'numbering' and date_key = v_today;

  if found then
    if v_existing_seed is distinct from v_expected_seed
       or v_existing_score is distinct from v_score
       or v_existing_digest is distinct from v_digest then
      raise exception 'daily score already submitted';
    end if;
    select public.get_my_daily_rank('numbering', v_today) into v_rank;
    return jsonb_build_object(
      'verified_score', v_existing_score,
      'previous_best', v_existing_score,
      'current_best', v_existing_score,
      'is_new_best', false,
      'is_idempotent', true,
      'date_key', v_today,
      'rank', v_rank
    );
  end if;

  perform set_config('app.numbering_verified_write', 'on', true);
  insert into public.daily_scores (
    user_id, game_id, date_key, seed, score, replay_code, summary_json
  ) values (
    v_user_id,
    'numbering',
    v_today,
    v_expected_seed,
    v_score,
    null,
    jsonb_build_object(
      'version', 2,
      'expression_sha256', v_digest,
      'verified_digits', v_expected_digits,
      'submission_rule', 'ordered_equality_single_entry'
    )
  );
  select public.get_my_daily_rank('numbering', v_today) into v_rank;
  return jsonb_build_object(
    'verified_score', v_score,
    'previous_best', null,
    'current_best', v_score,
    'is_new_best', true,
    'is_idempotent', false,
    'date_key', v_today,
    'rank', v_rank
  );
end;
$$;

revoke all on function public._numbering_daily_digits(integer)
from public, anon, authenticated;
revoke all on function public.submit_numbering_daily_result(integer, text)
from public, anon;
grant execute on function public.submit_numbering_daily_result(integer, text)
to authenticated;

notify pgrst, 'reload schema';
