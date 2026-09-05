-- ============================================================
-- 📧 NOTIFICATIONS EMAIL — Script à coller dans Supabase
-- Où : Supabase > SQL Editor > Nouvelle requête > coller > Run
-- ============================================================
-- Déclenche un email au restaurant quand un avis est déposé.

-- Étape 1 : Activer l'extension réseau (pg_net)
create extension if not exists pg_net;

-- Étape 2 : Créer la fonction qui appelle l'Edge Function "notifier"
create or replace function public.notifier_nouvel_avis()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://urpfgiaocxfnyfdoiapf.supabase.co/functions/v1/notifier',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVycGZnaWFvY3hmbnlmZG9pYXBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NDQ3MzMsImV4cCI6MjA5MDUyMDczM30.8OkTr_1pXbPn73e64Vgg8ovLGnkNNGDdWvmrzVBmzwo'
    ),
    body := jsonb_build_object('record', row_to_json(new))
  );
  return new;
end;
$$;

-- Étape 3 : Créer le déclencheur (trigger) sur la table avis
drop trigger if exists avis_notif_trigger on public.avis_internes;
create trigger avis_notif_trigger
after insert on public.avis_internes
for each row execute function public.notifier_nouvel_avis();

-- ✅ Terminé — Chaque nouvel avis déclenche un email au restaurant.
