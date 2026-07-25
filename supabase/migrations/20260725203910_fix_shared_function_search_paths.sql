-- Built-in-only helpers do not need a caller-controlled search path.
alter function public.set_updated_at() set search_path = '';
alter function public.normalize_room_code() set search_path = '';
alter function public.get_daily_challenge_seed(text, text) set search_path = '';
