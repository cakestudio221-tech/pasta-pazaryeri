-- NightCompare — Kullanıcılar kendi yorumlarını düzenleyebilsin/silebilsin
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

create policy "reviews_update_own" on reviews for update using (auth.uid() = user_id);
create policy "reviews_delete_own" on reviews for delete using (auth.uid() = user_id);
create policy "reviews_delete_admin" on reviews for delete using (is_admin());
