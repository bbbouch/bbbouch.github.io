-- Выполни целиком в Supabase → SQL Editor. Замени YOU@EXAMPLE.COM на свою почту.
create table public.responses (
  id uuid primary key,
  day text not null, time_slot text not null, custom_time text,
  plan text not null, custom_plan text,
  status text not null default 'received',
  created_at timestamptz not null default now()
);
alter table public.responses enable row level security;
revoke all on public.responses from anon, authenticated;
grant select on public.responses to authenticated;
-- читать может только владелец; анонимам прямого доступа к таблице нет вообще
create policy owner_read on public.responses for select to authenticated
  using ((auth.jwt() ->> 'email') = 'YOU@EXAMPLE.COM');

create or replace function public.submit_response(
  p_id uuid, p_day text, p_time text, p_custom_time text, p_plan text, p_custom_plan text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_day not in ('Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье')
     or char_length(p_time) not between 1 and 40
     or char_length(p_plan) not between 1 and 120
     or char_length(coalesce(p_custom_time,'')) > 100
     or char_length(coalesce(p_custom_plan,'')) > 500 then
    raise exception 'invalid input';
  end if;
  insert into public.responses(id, day, time_slot, custom_time, plan, custom_plan)
  values (p_id, p_day, p_time, nullif(p_custom_time,''), p_plan, nullif(p_custom_plan,''))
  on conflict (id) do nothing;  -- двойное нажатие не создаёт дубль
end $$;
revoke all on function public.submit_response(uuid,text,text,text,text,text) from public;
grant execute on function public.submit_response(uuid,text,text,text,text,text) to anon;
