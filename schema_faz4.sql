-- NightCompare — FAZ 4: Arayüz ve Deneyim
-- Önceki schema_*.sql dosyaları çalıştırıldıysa, sadece bu dosyayı SQL Editor'de çalıştırman yeterli.

alter table profiles add column theme_preference text not null default 'system'
  check (theme_preference in ('system','light','dark'));
