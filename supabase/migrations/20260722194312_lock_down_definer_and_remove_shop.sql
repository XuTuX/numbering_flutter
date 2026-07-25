begin;

-- 1) 모든 public SECURITY DEFINER 함수의 기본 API 실행 권한 회수
DO $do$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure::text AS signature
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', r.signature);
  END LOOP;
END
$do$;

-- 2) 공개 조회용 SECURITY DEFINER 함수만 anon/authenticated에 재허용
DO $do$
DECLARE
  sig text;
  allowed text[] := ARRAY[
    'public.get_all_time_leaderboard(text,integer)',
    'public.get_daily_challenge(text)',
    'public.get_daily_leaderboard(text,text,integer)',
    'public.get_leaderboard(text,integer)',
    'public.get_leaderboard_by_days(text,integer,integer)',
    'public.get_weekly_leaderboard(text,integer)',
    'public.get_weekly_leaderboard_by_week(text,text,integer)',
    'public.is_nickname_available(text)'
  ];
BEGIN
  FOREACH sig IN ARRAY allowed LOOP
    IF to_regprocedure(sig) IS NOT NULL THEN
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO anon, authenticated', sig);
    END IF;
  END LOOP;
END
$do$;

-- 3) 로그인 사용자 본인용 함수만 authenticated에 재허용
DO $do$
DECLARE
  sig text;
  allowed text[] := ARRAY[
    'public.claim_daily_challenge_entry(text)',
    'public.delete_my_account_completely()',
    'public.delete_my_account_data()',
    'public.get_my_all_time_best_score(text)',
    'public.get_my_all_time_rank(text)',
    'public.get_my_best_score(text)',
    'public.get_my_daily_best_score(text,text)',
    'public.get_my_daily_rank(text,text)',
    'public.get_my_rank(text)',
    'public.get_my_weekly_best_score(text)',
    'public.get_my_weekly_best_score_by_week(text,text)',
    'public.get_my_weekly_rank(text)',
    'public.get_my_weekly_rank_by_week(text,text)',
    'public.get_my_weekly_season_summary(text)',
    'public.submit_hexor_verified_run(integer,integer,text,text,text)',
    'public.update_my_nickname(text)'
  ];
BEGIN
  FOREACH sig IN ARRAY allowed LOOP
    IF to_regprocedure(sig) IS NOT NULL THEN
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', sig);
    END IF;
  END LOOP;
END
$do$;

-- 4) 결제·재화·상점 함수 전체 삭제
DO $do$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure::text AS signature
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'shop\_%' ESCAPE '\'
  LOOP
    EXECUTE format('DROP FUNCTION %s RESTRICT', r.signature);
  END LOOP;
END
$do$;

-- 5) 검증을 우회할 수 있는 과거 점수 제출 경로 제거
DROP FUNCTION IF EXISTS public.update_best_score(text, integer) RESTRICT;
DROP FUNCTION IF EXISTS public.submit_score(text, integer) RESTRICT;
DROP FUNCTION IF EXISTS public.submit_daily_score(text, text, integer, integer, text, text) RESTRICT;
DROP FUNCTION IF EXISTS public.submit_weekly_score(text, integer) RESTRICT;

-- 6) 클라이언트의 점수 테이블 직접 쓰기 정책 제거
DROP POLICY IF EXISTS "Users can insert own scores" ON public.scores;
DROP POLICY IF EXISTS weekly_scores_insert_own ON public.weekly_scores;
DROP POLICY IF EXISTS weekly_scores_update_own ON public.weekly_scores;
DROP POLICY IF EXISTS weekly_scores_delete_own ON public.weekly_scores;

-- 7) 테이블 수준 DML 권한도 명시적으로 회수
REVOKE INSERT, UPDATE, DELETE ON TABLE public.scores FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.daily_scores FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.daily_attempts FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.weekly_scores FROM anon, authenticated;

commit;
