-- Keep the equality scoring rule, but generate all eight digits independently.

create or replace function public._numbering_daily_digits(p_seed integer)
returns text
language plpgsql
immutable
strict
set search_path = public
as $$
declare
  v_modulus constant bigint := 2147483647;
  v_state bigint := p_seed::bigint % v_modulus;
  v_digits text := '';
  v_index integer;
begin
  if v_state <= 0 then v_state := v_state + v_modulus - 1; end if;
  for v_index in 1..8 loop
    v_state := (v_state * 48271) % v_modulus;
    v_digits := v_digits || (1 + (v_state % 9))::text;
  end loop;
  return v_digits;
end;
$$;

revoke all on function public._numbering_daily_digits(integer)
from public, anon, authenticated;

notify pgrst, 'reload schema';
