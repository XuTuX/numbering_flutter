-- daily_scores 테이블의 user_id가 profiles 테이블을 참조하도록 외래 키 추가
ALTER TABLE public.daily_scores
DROP CONSTRAINT IF EXISTS daily_scores_user_id_fkey,
ADD CONSTRAINT daily_scores_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.profiles(id)
ON DELETE CASCADE;

-- daily_attempts 테이블도 동일하게 처리
ALTER TABLE public.daily_attempts
DROP CONSTRAINT IF EXISTS daily_attempts_user_id_fkey,
ADD CONSTRAINT daily_attempts_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.profiles(id)
ON DELETE CASCADE;

-- weekly_scores 테이블도 동일하게 처리 (일관성 유지)
ALTER TABLE public.weekly_scores
DROP CONSTRAINT IF EXISTS weekly_scores_user_id_fkey,
ADD CONSTRAINT weekly_scores_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.profiles(id)
ON DELETE CASCADE;
