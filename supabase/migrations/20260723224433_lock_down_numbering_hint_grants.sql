-- Reward grants are server-only. Signed-in clients may sync and consume hints,
-- but cannot mint them directly.

revoke all on function public.add_my_numbering_hints(integer)
from public, anon, authenticated;
