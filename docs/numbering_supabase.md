# Numbering Supabase integration

## Time Attack

Time Attack is an authenticated, server-timed three-minute session. The client
starts a session with `start_numbering_time_attack()`. Supabase selects each
4-, 5-, or 6-digit puzzle from the private canonical level catalog and returns
the server expiration time.

Every solution is sent to
`submit_numbering_time_attack_solution(session_id, puzzle_index, expression)`.
The database checks session ownership and expiration, the exact digit multiset,
allowed expression syntax, integer arithmetic, and equality before updating the
session's highest number and total score. Puzzle indexes make retries
idempotent. The client never sends a trusted numeric score.

When the server timer expires, `finish_numbering_time_attack(session_id)`
finalizes the session and updates the user's best record only when the ordering
tuple improves: highest number descending, total score descending, then the
earlier highest-number time. Rankings come from
`get_numbering_time_attack_leaderboard(limit)` and include the current user's
row even when it falls outside the requested top results.

## Data access

`private.numbering_time_attack_sessions` and
`private.numbering_time_attack_solutions` are inaccessible to Data API roles.
`public.numbering_time_attack_scores` has RLS enabled and grants authenticated
read access only. Writes are available only through authenticated RPCs that
check `auth.uid()`; all functions revoke execution from `public` and `anon`.

Arcade progress remains local and never writes ranking data. Shared daily tables
and generic daily RPCs remain in the project because other NEOREO games use
them, but all `numbering` daily rows and Numbering-specific daily objects were
removed by `20260725193742_remove_numbering_daily.sql`.
