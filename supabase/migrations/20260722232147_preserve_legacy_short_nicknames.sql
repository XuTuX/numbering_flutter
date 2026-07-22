-- Some existing NEOREO profiles intentionally use a one-character nickname.
-- Keep those values valid for unrelated profile updates. New nickname writes
-- are still restricted to 2-24 characters by both nickname RPCs.

alter table public.profiles
drop constraint if exists profiles_nickname_length_check;

comment on function public.update_my_nickname(text) is
  'Updates the authenticated user nickname after enforcing a trimmed 2-24 character value.';

comment on function public.ensure_my_nickname(text) is
  'Assigns a 2-24 character nickname only when the authenticated user does not already have one.';
