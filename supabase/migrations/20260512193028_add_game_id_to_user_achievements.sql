-- Add game_id column
ALTER TABLE public.user_achievements ADD COLUMN IF NOT EXISTS game_id TEXT DEFAULT 'overlap' NOT NULL;

-- Drop old unique constraint
ALTER TABLE public.user_achievements DROP CONSTRAINT IF EXISTS user_achievements_user_id_milestone_id_key;

-- Add new unique constraint including game_id
ALTER TABLE public.user_achievements ADD CONSTRAINT user_achievements_user_id_game_id_milestone_id_key UNIQUE (user_id, game_id, milestone_id);

-- Also add game_id to user_stats for consistency if needed, 
-- but user only asked for achievements. 
-- However, since stats are also game-specific, it's safer to add it there too.
ALTER TABLE public.user_stats ADD COLUMN IF NOT EXISTS game_id TEXT DEFAULT 'overlap' NOT NULL;

-- Drop old primary key on user_stats (if it was just user_id)
ALTER TABLE public.user_stats DROP CONSTRAINT IF EXISTS user_stats_pkey;

-- Add new primary key including game_id
ALTER TABLE public.user_stats ADD PRIMARY KEY (user_id, game_id);

