-- NightCompare — Bildirimler + Mekan Düzenleme
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

-- Bildirim merkezi
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  body text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
alter table notifications enable row level security;
create policy "notifications_select_own" on notifications for select using (auth.uid() = user_id);
create policy "notifications_update_own" on notifications for update using (auth.uid() = user_id);
-- Insert policy yok: bildirimler sadece aşağıdaki trigger'lar (security definer) tarafından oluşturulur.

-- Mekan onaylanınca bildirim
create or replace function notify_venue_approved() returns trigger as $$
begin
  if new.is_approved = true and old.is_approved = false and new.created_by is not null then
    insert into notifications (user_id, title, body) values (new.created_by, 'Mekanın onaylandı! 🎉', new.name || ' artık herkese görünür.');
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger notify_venue_approved_trigger after update on venues
  for each row execute procedure notify_venue_approved();

-- Doğrulama başvurusu sonuçlanınca bildirim
create or replace function notify_verification_reviewed() returns trigger as $$
declare venue_name text;
begin
  if new.status in ('approved','rejected') and old.status = 'pending' then
    select name into venue_name from venues where id = new.venue_id;
    insert into notifications (user_id, title, body) values (
      new.user_id,
      case when new.status='approved' then 'Doğrulama başvurun onaylandı ✅' else 'Doğrulama başvurun reddedildi' end,
      venue_name
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger notify_verification_reviewed_trigger after update on venue_verification_requests
  for each row execute procedure notify_verification_reviewed();

-- Mekan düzenleme yetkisi: sahibi kendi eklediği mekanı güncelleyebilir
create policy "venues_owner_update" on venues for update using (auth.uid() = created_by);

-- İsim/semt/fotoğraf değişirse (admin hariç) yeniden onaya düşsün — kötüye kullanımı önler
create or replace function require_reapproval_on_venue_edit() returns trigger as $$
begin
  if not is_admin() and (new.name is distinct from old.name or new.district is distinct from old.district or new.img is distinct from old.img) then
    new.is_approved = false;
  end if;
  return new;
end;
$$ language plpgsql security definer;
create trigger require_reapproval_on_venue_edit_trigger before update on venues
  for each row execute procedure require_reapproval_on_venue_edit();
