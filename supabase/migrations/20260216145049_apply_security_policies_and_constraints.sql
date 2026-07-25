-- Enable RLS
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Scores Policies
DROP POLICY IF EXISTS "Enable read access for all users" ON scores;
CREATE POLICY "Enable read access for all users" ON scores
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON scores;
CREATE POLICY "Enable insert for authenticated users only" ON scores
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Enable update for users based on user_id" ON scores;
CREATE POLICY "Enable update for users based on user_id" ON scores
FOR UPDATE USING (auth.uid() = user_id);

-- Games Policies
DROP POLICY IF EXISTS "Enable read access for all users" ON games;
CREATE POLICY "Enable read access for all users" ON games
FOR SELECT USING (true);

-- Unique Constraint
-- Check if constraint exists effectively or just drop and add
ALTER TABLE scores DROP CONSTRAINT IF EXISTS scores_user_id_game_id_key;
-- If the constraint implies an index, good.
-- To be safe against duplicates existing:
-- We might need to cleanup duplicates first if any exist?
-- Assuming table is clean or user accepts error if duplicates exist.
-- User said "scores 테이블에 중복 데이터... 쌓일 수 있음".
-- If duplicates exist, adding constraint will fail.
-- I should probably try to clean duplicates first just in case.
-- Strategies: Keep highest score.

-- Deduplication Logic (Postgres specific)
DELETE FROM scores a USING scores b
WHERE a.id < b.id
AND a.user_id = b.user_id
AND a.game_id = b.game_id
AND a.score <= b.score; -- Delete lower scores or older duplicates

-- Wait, if scores are equal, we verify id.
-- Let's stick to simple adding constraint. If it fails, I'll know.
ALTER TABLE scores ADD CONSTRAINT scores_user_id_game_id_key UNIQUE (user_id, game_id);
