-- NightCompare — FAZ 3: Kullanıcı Hesabı ve Sosyal Özellikler
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- 3.3 Liderlik Tablosu
create or replace view user_contribution_stats as
select
  p.id as user_id,
  p.username,
  coalesce(pr7.cnt,0) as contributions_7d,
  coalesce(pr30.cnt,0) as contributions_30d,
  coalesce(prall.cnt,0) as contributions_all
from profiles p
left join (select reported_by, count(*) cnt from prices where reported_by is not null and created_at > now() - interval '7 days' group by reported_by) pr7 on pr7.reported_by = p.id
left join (select reported_by, count(*) cnt from prices where reported_by is not null and created_at > now() - interval '30 days' group by reported_by) pr30 on pr30.reported_by = p.id
left join (select reported_by, count(*) cnt from prices where reported_by is not null group by reported_by) prall on prall.reported_by = p.id;

grant select on user_contribution_stats to anon, authenticated;

-- 3.4 Doğrulanmış Mekan Rozeti başvuruları
create table venue_verification_requests (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references venues(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  message text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
alter table venue_verification_requests enable row level security;
create policy "vvr_select_own" on venue_verification_requests for select using (auth.uid() = user_id);
create policy "vvr_insert_own" on venue_verification_requests for insert with check (auth.uid() = user_id and status = 'pending');
-- Kasıtlı olarak update policy yok: normal kullanıcılar kendi başvurularının durumunu değiştiremez,
-- sadece proje sahibi Supabase Table Editor'den (RLS'i bypass eden servis rolüyle) statüyü değiştirebilir.

create or replace function handle_venue_verification_approval()
returns trigger as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    update venues set verified = true where id = new.venue_id;
    new.reviewed_at = now();
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_venue_verification_status_change
  before update on venue_verification_requests
  for each row execute procedure handle_venue_verification_approval();
