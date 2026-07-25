
-- 1. 플레이어가 룸에 입장/준비할 때 자신의 블록 색상을 저장하는 컬럼
ALTER TABLE multiplayer_room_players
  ADD COLUMN IF NOT EXISTS block_color INTEGER;

-- 2. 게임 시작 시 각 플레이어의 최종 블록 색상을 방에 저장하는 컬럼
--    host_block_color: 방장의 블록 색상 (ARGB32 정수)
--    guest_block_color: 게스트의 블록 색상 (ARGB32 정수)
ALTER TABLE multiplayer_rooms
  ADD COLUMN IF NOT EXISTS host_block_color INTEGER,
  ADD COLUMN IF NOT EXISTS guest_block_color INTEGER;

