-- ============================================================
-- 📸 PHOTOS DANS LES AVIS — Script à coller dans Supabase
-- Où : Supabase > SQL Editor > Nouvelle requête > coller > Run
-- ============================================================
-- Permet au client de joindre une photo à son avis.

-- Étape 1 : Ajouter la colonne "photo_url" à la table des avis
alter table public.avis_internes
add column if not exists photo_url text;

-- Étape 2 : Créer le "bucket" de stockage des photos (si absent)
insert into storage.buckets (id, name, public)
values ('avis-photos', 'avis-photos', true)
on conflict (id) do nothing;

-- Étape 3 : Autoriser le public à déposer une photo
drop policy if exists "public_upload_photos" on storage.objects;
create policy "public_upload_photos" on storage.objects
for insert to anon, authenticated
with check (bucket_id = 'avis-photos');

-- Étape 4 : Autoriser la lecture publique des photos
drop policy if exists "public_read_photos" on storage.objects;
create policy "public_read_photos" on storage.objects
for select to anon, authenticated
using (bucket_id = 'avis-photos');

-- ✅ Terminé — Le client peut maintenant joindre une photo à son avis.
