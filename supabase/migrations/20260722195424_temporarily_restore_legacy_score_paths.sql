begin;

create or replace function public.submit_score(p_game_id text, p_score integer)
returns table(saved_score integer, updated boolean)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_uid uuid := auth.uid();
  v_before integer;
  v_after integer;
begin
  if v_uid is null then raise exception 'authentication required'; end if;
  if p_score is null or p_score < 0 then raise exception 'invalid score'; end if;
  if not exists (select 1 from public.games where id = p_game_id) then raise exception 'invalid game'; end if;

  select score into v_before from public.scores where user_id=v_uid and game_id=p_game_id;
  insert into public.scores(user_id,game_id,score)
  values(v_uid,p_game_id,p_score)
  on conflict(user_id,game_id) do update
    set score=greatest(public.scores.score,excluded.score), updated_at=case when excluded.score>public.scores.score then now() else public.scores.updated_at end;
  select score into v_after from public.scores where user_id=v_uid and game_id=p_game_id;
  return query select v_after, coalesce(v_after>v_before,true);
end;
$function$;

create or replace function public.update_best_score(p_game_id text, p_score integer)
returns integer
language plpgsql
security definer
set search_path = public
as $function$
declare v_result integer;
begin
  select saved_score into v_result from public.submit_score(p_game_id,p_score);
  return v_result;
end;
$function$;

create or replace function public.submit_weekly_score(p_game_id text, p_score integer)
returns integer
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_uid uuid := auth.uid();
  v_week text := to_char(timezone('Asia/Seoul',now()),'IYYY-IW');
  v_score integer;
begin
  if v_uid is null then raise exception 'authentication required'; end if;
  if p_score is null or p_score < 0 then raise exception 'invalid score'; end if;
  if not exists (select 1 from public.games where id=p_game_id) then raise exception 'invalid game'; end if;
  insert into public.weekly_scores(user_id,game_id,week_key,score)
  values(v_uid,p_game_id,v_week,p_score)
  on conflict(user_id,game_id,week_key) do update
    set score=greatest(public.weekly_scores.score,excluded.score), updated_at=case when excluded.score>public.weekly_scores.score then now() else public.weekly_scores.updated_at end;
  select score into v_score from public.weekly_scores where user_id=v_uid and game_id=p_game_id and week_key=v_week;
  return v_score;
end;
$function$;

create or replace function public.submit_daily_score(
  p_game_id text,
  p_date_key text,
  p_seed integer,
  p_score integer,
  p_replay_code text,
  p_summary_json text
)
returns integer
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_uid uuid := auth.uid();
  v_today text := to_char(timezone('Asia/Seoul',now()),'YYYY-MM-DD');
  v_expected_seed integer;
  v_score integer;
begin
  if v_uid is null then raise exception 'authentication required'; end if;
  if p_date_key <> v_today then raise exception 'invalid date'; end if;
  if p_score is null or p_score < 0 then raise exception 'invalid score'; end if;
  if not exists (select 1 from public.games where id=p_game_id) then raise exception 'invalid game'; end if;

  select public.get_daily_challenge_seed(p_game_id,p_date_key) into v_expected_seed;
  if v_expected_seed is distinct from p_seed then raise exception 'invalid seed'; end if;
  if not exists (
    select 1 from public.daily_attempts
    where user_id=v_uid and game_id=p_game_id and date_key=p_date_key
  ) then raise exception 'daily entry not claimed'; end if;

  insert into public.daily_scores(user_id,game_id,date_key,seed,score,replay_code,summary_json)
  values(v_uid,p_game_id,p_date_key,p_seed,p_score,p_replay_code,
         case when p_summary_json is null or btrim(p_summary_json)='' then null else p_summary_json::jsonb end)
  on conflict(user_id,game_id,date_key) do update
    set score=greatest(public.daily_scores.score,excluded.score),
        replay_code=case when excluded.score>=public.daily_scores.score then excluded.replay_code else public.daily_scores.replay_code end,
        summary_json=case when excluded.score>=public.daily_scores.score then excluded.summary_json else public.daily_scores.summary_json end,
        updated_at=case when excluded.score>public.daily_scores.score then now() else public.daily_scores.updated_at end;
  select score into v_score from public.daily_scores where user_id=v_uid and game_id=p_game_id and date_key=p_date_key;
  return v_score;
end;
$function$;

revoke execute on function public.submit_score(text,integer) from public, anon;
revoke execute on function public.update_best_score(text,integer) from public, anon;
revoke execute on function public.submit_weekly_score(text,integer) from public, anon;
revoke execute on function public.submit_daily_score(text,text,integer,integer,text,text) from public, anon;
grant execute on function public.submit_score(text,integer) to authenticated;
grant execute on function public.update_best_score(text,integer) to authenticated;
grant execute on function public.submit_weekly_score(text,integer) to authenticated;
grant execute on function public.submit_daily_score(text,text,integer,integer,text,text) to authenticated;

create policy "Users can insert own scores" on public.scores for insert to authenticated with check ((select auth.uid())=user_id);
create policy weekly_scores_insert_own on public.weekly_scores for insert to authenticated with check ((select auth.uid())=user_id);
create policy weekly_scores_update_own on public.weekly_scores for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy weekly_scores_delete_own on public.weekly_scores for delete to authenticated using ((select auth.uid())=user_id);

grant insert on table public.scores to authenticated;
grant insert,update,delete on table public.weekly_scores to authenticated;

commit;
