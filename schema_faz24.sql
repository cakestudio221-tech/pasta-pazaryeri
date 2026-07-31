-- NightCompare — Canlı "Buradayım" check-in özelliği
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

create table venue_checkins (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table venue_checkins enable row level security;
create policy "venue_checkins_select_all" on venue_checkins for select using (true);
create policy "venue_checkins_insert_own" on venue_checkins for insert with check (auth.uid() = user_id);

-- Aynı kullanıcı aynı mekana son 4 saat içinde tekrar check-in yapamasın
create or replace function check_recent_checkin() returns trigger as $$
begin
  if exists (
    select 1 from venue_checkins
    where venue_id = new.venue_id and user_id = new.user_id
      and created_at > now() - interval '4 hours'
  ) then
    raise exception 'Bu mekana zaten yakın zamanda check-in yaptın';
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger check_recent_checkin_trigger before insert on venue_checkins
  for each row execute procedure check_recent_checkin();
