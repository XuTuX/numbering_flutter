CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
begin
  insert into public.profiles (id, nickname, avatar_url)
  values (
    new.id,
    null, -- Change from full_name to null to trigger nickname setup in app
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;
