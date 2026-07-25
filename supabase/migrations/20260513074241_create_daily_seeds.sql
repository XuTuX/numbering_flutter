CREATE TABLE daily_seeds (
  date TEXT PRIMARY KEY,
  seed INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- RLS: Nobody can read directly. Only service_role (via edge function) can read/write.
ALTER TABLE daily_seeds ENABLE ROW LEVEL SECURITY;

