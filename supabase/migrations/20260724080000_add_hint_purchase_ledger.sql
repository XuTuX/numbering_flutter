-- Idempotent ledger for consumable App Store / Google Play hint purchases.
-- Store receipts are verified by the verify-hint-purchase Edge Function. Only
-- the service role used by that function can call the grant RPC.

alter table public.numbering_user_resources
  drop constraint if exists numbering_user_resources_hint_count_check;

alter table public.numbering_user_resources
  add constraint numbering_user_resources_hint_count_check
  check (hint_count between 0 and 1000000);

create table public.numbering_hint_purchases (
  store text not null check (store in ('apple', 'google')),
  transaction_id text not null,
  user_id uuid not null references auth.users(id) on delete restrict,
  product_id text not null check (
    product_id in (
      'numbering_hints_11',
      'numbering_hints_50',
      'numbering_hints_100'
    )
  ),
  hint_amount integer not null check (hint_amount in (11, 50, 100)),
  store_environment text,
  purchased_at timestamptz,
  payload_sha256 text not null check (payload_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  primary key (store, transaction_id)
);

alter table public.numbering_hint_purchases enable row level security;

create policy "hint purchases are owner readable"
on public.numbering_hint_purchases
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.numbering_hint_purchases from public, anon;
grant select on table public.numbering_hint_purchases to authenticated;

create or replace function public.grant_verified_numbering_hint_purchase(
  p_user_id uuid,
  p_store text,
  p_transaction_id text,
  p_product_id text,
  p_store_environment text,
  p_purchased_at timestamptz,
  p_payload_sha256 text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hint_amount integer := case p_product_id
    when 'numbering_hints_11' then 11
    when 'numbering_hints_50' then 50
    when 'numbering_hints_100' then 100
    else null
  end;
  v_inserted boolean := false;
  v_existing_user_id uuid;
  v_existing_product_id text;
  v_hint_count integer;
begin
  if p_user_id is null then
    raise exception 'user id is required' using errcode = '22023';
  end if;
  if p_store not in ('apple', 'google') then
    raise exception 'unsupported store' using errcode = '22023';
  end if;
  if p_transaction_id is null or length(p_transaction_id) < 8
      or length(p_transaction_id) > 512 then
    raise exception 'invalid transaction id' using errcode = '22023';
  end if;
  if v_hint_amount is null then
    raise exception 'unknown product id' using errcode = '22023';
  end if;
  if p_payload_sha256 is null
      or p_payload_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid payload hash' using errcode = '22023';
  end if;

  insert into public.numbering_hint_purchases (
    store,
    transaction_id,
    user_id,
    product_id,
    hint_amount,
    store_environment,
    purchased_at,
    payload_sha256
  ) values (
    p_store,
    p_transaction_id,
    p_user_id,
    p_product_id,
    v_hint_amount,
    nullif(left(p_store_environment, 32), ''),
    p_purchased_at,
    p_payload_sha256
  )
  on conflict (store, transaction_id) do nothing
  returning true into v_inserted;

  if not coalesce(v_inserted, false) then
    select user_id, product_id
      into v_existing_user_id, v_existing_product_id
    from public.numbering_hint_purchases
    where store = p_store and transaction_id = p_transaction_id;

    if v_existing_user_id is distinct from p_user_id
        or v_existing_product_id is distinct from p_product_id then
      raise exception 'transaction was already claimed' using errcode = '23505';
    end if;
  else
    insert into public.numbering_user_resources (
      user_id,
      hint_count,
      last_attendance_date,
      is_initialized,
      updated_at
    ) values (
      p_user_id,
      least(20 + v_hint_amount, 1000000),
      timezone('Asia/Seoul', now())::date,
      true,
      now()
    )
    on conflict (user_id) do update
    set hint_count = least(
          public.numbering_user_resources.hint_count + v_hint_amount,
          1000000
        ),
        last_attendance_date = coalesce(
          public.numbering_user_resources.last_attendance_date,
          timezone('Asia/Seoul', now())::date
        ),
        is_initialized = true,
        updated_at = now();
  end if;

  select hint_count into v_hint_count
  from public.numbering_user_resources
  where user_id = p_user_id;

  return jsonb_build_object(
    'granted', coalesce(v_inserted, false),
    'already_granted', not coalesce(v_inserted, false),
    'hint_amount', v_hint_amount,
    'hint_count', v_hint_count
  );
end;
$$;

revoke all on function public.grant_verified_numbering_hint_purchase(
  uuid, text, text, text, text, timestamptz, text
) from public, anon, authenticated;
grant execute on function public.grant_verified_numbering_hint_purchase(
  uuid, text, text, text, text, timestamptz, text
) to service_role;

-- Keep the attendance sync compatible with balances above the old 9,999 cap.
create or replace function public.sync_my_numbering_hints(
  p_local_hint_count integer default 20,
  p_local_last_attendance_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_today date := timezone('Asia/Seoul', now())::date;
  v_count integer;
  v_last_date date;
  v_initialized boolean;
  v_awarded boolean := false;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  insert into public.numbering_user_resources (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select hint_count, last_attendance_date, is_initialized
  into v_count, v_last_date, v_initialized
  from public.numbering_user_resources
  where user_id = v_user_id
  for update;

  if not v_initialized then
    v_count := greatest(0, least(coalesce(p_local_hint_count, 20), 1000000));
    v_last_date := coalesce(p_local_last_attendance_date, v_today);
    update public.numbering_user_resources
    set hint_count = v_count,
        last_attendance_date = v_last_date,
        is_initialized = true,
        updated_at = now()
    where user_id = v_user_id;
  end if;

  if v_last_date is null or v_last_date < v_today then
    v_count := least(v_count + 3, 1000000);
    v_last_date := v_today;
    v_awarded := true;
    update public.numbering_user_resources
    set hint_count = v_count,
        last_attendance_date = v_last_date,
        updated_at = now()
    where user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'hint_count', v_count,
    'last_attendance_date', v_last_date,
    'attendance_awarded', v_awarded
  );
end;
$$;

revoke all on function public.sync_my_numbering_hints(integer, date)
from public, anon;
grant execute on function public.sync_my_numbering_hints(integer, date)
to authenticated;
