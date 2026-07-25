-- 1. scores 테이블에 대한 본인 수정 권한 추가
CREATE POLICY "Users can update their own scores."
ON public.scores
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 2. games 테이블 RLS 활성화 및 읽기 전용 정책 추가 (보안 강화)
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to games."
ON public.games
FOR SELECT
USING (true);

-- 3. 데이터 무결성을 위해 scores 테이블에 유니크 제약 조건 추가 (중복 데이터 방지)
-- 이미 중복된 데이터가 있다면 삭제 후 적용해야 하지만, 현재 초기 단계라 가정하고 적용 시도
ALTER TABLE public.scores ADD CONSTRAINT unique_user_game_score UNIQUE (user_id, game_id);
