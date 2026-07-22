-- Preserve existing profile nicknames while making new writes normalized,
-- case-insensitively unique, and safe under concurrent app startup requests.

create unique index if not exists profiles_nickname_unique_ci
on public.profiles (lower(btrim(nickname)))
where nickname is not null and btrim(nickname) <> '';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_nickname_trimmed_check'
  ) then
    alter table public.profiles
      add constraint profiles_nickname_trimmed_check
      check (nickname is null or nickname = btrim(nickname));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_nickname_length_check'
  ) then
    -- Preserve legacy one-character nicknames while enforcing this check for
    -- all future inserts and updates.
    alter table public.profiles
      add constraint profiles_nickname_length_check
      check (nickname is null or char_length(nickname) between 2 and 24)
      not valid;
  end if;
end;
$$;

create or replace function public.update_my_nickname(p_nickname text)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_nickname text := btrim(coalesce(p_nickname, ''));
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if char_length(v_nickname) < 2 or char_length(v_nickname) > 24 then
    raise exception 'nickname_length_invalid' using errcode = '22023';
  end if;

  begin
    insert into public.profiles (id, nickname)
    values (v_user_id, v_nickname)
    on conflict (id) do update
      set nickname = excluded.nickname;
  exception
    when unique_violation then
      raise exception 'nickname_already_exists' using errcode = '23505';
  end;

  return v_nickname;
end;
$$;

-- Automatic assignment never overwrites an existing nickname. This makes
-- repeated/concurrent profile loads idempotent.
create or replace function public.ensure_my_nickname(p_nickname text)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_candidate text := btrim(coalesce(p_nickname, ''));
  v_saved text;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if char_length(v_candidate) < 2 or char_length(v_candidate) > 24 then
    raise exception 'nickname_length_invalid' using errcode = '22023';
  end if;

  begin
    insert into public.profiles as profiles (id, nickname)
    values (v_user_id, v_candidate)
    on conflict (id) do update
      set nickname = excluded.nickname
      where profiles.nickname is null or btrim(profiles.nickname) = ''
    returning nickname into v_saved;
  exception
    when unique_violation then
      raise exception 'nickname_already_exists' using errcode = '23505';
  end;

  if v_saved is null then
    select btrim(profiles.nickname)
    into v_saved
    from public.profiles as profiles
    where profiles.id = v_user_id;
  end if;

  return v_saved;
end;
$$;

revoke all on function public.update_my_nickname(text) from public;
revoke all on function public.update_my_nickname(text) from anon;
grant execute on function public.update_my_nickname(text) to authenticated;

revoke all on function public.ensure_my_nickname(text) from public;
revoke all on function public.ensure_my_nickname(text) from anon;
grant execute on function public.ensure_my_nickname(text) to authenticated;

grant select, insert, update on table public.profiles to authenticated;

notify pgrst, 'reload schema';
