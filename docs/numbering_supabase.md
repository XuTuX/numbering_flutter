# Numbering Supabase integration

## Verified game rules

Numbering's database game ID is `numbering`. The current game has 160 fixed
levels. A normal level is complete when the player uses the level's digits in
their original order, uses only its enabled operators, creates exactly one
equality, and both integer-valued sides are equal. The score is that shared
integer value. A result below the level's `minimumScore` is not submitted as a
cleared stage. Hints affect the local star evaluation, not the numeric score.

The official daily game has no level or difficulty selector. It contains eight
digits from 1 through 9. The player may reorder those digits by drag and drop,
must use every occurrence exactly once, create exactly one equality, and make
both integer-valued sides equal. The shared value is the daily score, so the
goal is to find the valid equation with the largest possible shared value.
There is no timer, move limit, wrong-answer count, or combo in the current
Numbering code.

## Deterministic daily puzzle

`generateDailyNumberingPuzzle(seed)` uses the Park-Miller PRNG. Its arithmetic
stays in the exact integer range on native Dart and Flutter web. All eight
digits are generated independently from 1 through 9; no baseline equation is
embedded in the puzzle. The SQL helper `_numbering_daily_digits(seed)`
implements the same sequence. The daily seed and date come from
`get_daily_challenge('numbering')`; client local time is not used for an
official attempt.

## Submission policy

Normal results call `submit_numbering_result(level_id, expression, used_hints)`.
The function loads the canonical level rule copied from `LevelCatalog`, parses
the expression without dynamic SQL, calculates the score, and updates all-time
and current-week best rows only when the verified score is higher.

Daily games follow the existing single-entry policy. The client calls
`claim_daily_challenge_entry('numbering')` before play and then calls
`submit_numbering_daily_result(seed, expression)`. The first valid result is
final. An identical retry is idempotent; a different result for the same day is
rejected. A claim response lost to the network is recovered by reading the
existing unfinished attempt with the same server seed.

Direct `numbering` writes through `scores`, `daily_scores`, or `weekly_scores`
are rejected by table triggers. Existing games and their compatibility RPCs are
unchanged. The generic all-time, weekly, and daily leaderboard RPCs remain the
single ranking implementation.

## Remaining verification limits

The server fully validates the final expression and its canonical puzzle, but
the current game does not record a timed action replay. The server therefore
cannot prove that a human entered the expression through the visible controls,
measure solve time, or distinguish reopening an unfinished claimed daily attempt
from restoring the same UI session. A future anti-automation layer should add a
server-issued attempt nonce and a bounded action log, then replay those actions
against the same deterministic puzzle before accepting the final expression.

Migration `20260722200417_add_numbering_rankings.sql` was applied to the
`neoreo-core` Supabase project on 2026-07-23 after review. Post-deployment checks
confirmed all 160 canonical rules, the `numbering` game and score-rule rows,
authenticated-only submission RPC permissions, an eight-digit KST daily puzzle,
and matching Dart/SQL deterministic output.
