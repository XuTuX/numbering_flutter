-- Remove only NUMBERING's retired daily/legacy ranking data and objects.
-- Shared daily tables and generic RPCs remain because other games use them.

delete from public.daily_scores where game_id = 'numbering';
delete from public.daily_attempts where game_id = 'numbering';
delete from public.weekly_scores where game_id = 'numbering';
delete from public.scores where game_id = 'numbering';
delete from public.game_score_rules where game_id = 'numbering';

drop table if exists public.numbering_daily_progress;

drop function if exists public.submit_numbering_daily_result(integer, text);
drop function if exists public._numbering_daily_digits(integer);
drop function if exists public._numbering_challenge_period_key(timestamptz);
drop function if exists public.submit_numbering_result(integer, text, integer);

drop trigger if exists guard_numbering_scores on public.scores;
drop trigger if exists guard_numbering_daily_scores on public.daily_scores;
drop trigger if exists guard_numbering_weekly_scores on public.weekly_scores;
drop function if exists public._guard_numbering_verified_write();
