begin;

DROP FUNCTION IF EXISTS public.enforce_max_players() RESTRICT;
DROP FUNCTION IF EXISTS public.multiplayer_get_room_player_counts(uuid[], text) RESTRICT;
DROP FUNCTION IF EXISTS public.multiplayer_is_room_participant(uuid, text) RESTRICT;
DROP FUNCTION IF EXISTS public.multiplayer_ranked_queue_cancel(text, text) RESTRICT;
DROP FUNCTION IF EXISTS public.multiplayer_ranked_queue_match(text, text, text, text, bigint, bigint, integer, integer) RESTRICT;
DROP FUNCTION IF EXISTS public.multiplayer_ranked_quick_match(text, text, text, text, bigint, bigint, integer) RESTRICT;
DROP FUNCTION IF EXISTS public.multiplayer_transfer_room_host(uuid, uuid) RESTRICT;

commit;
