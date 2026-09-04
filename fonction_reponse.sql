-- ============================================================
-- 📝 FONCTION « RÉPONDRE AUX AVIS » — Script à coller dans Supabase
-- Où : Supabase > SQL Editor > Nouvelle requête > coller > Run
-- ============================================================
-- Ajoute la capacité au restaurant de répondre à un avis.

-- Étape 1 : Ajouter la colonne "reponse" à la table des avis
alter table public.avis_internes
add column if not exists reponse text;

-- Étape 2 : Autoriser le proprio à répondre (mettre à jour) SES avis
create policy "avis_proprio_update" on public.avis_internes
for update to authenticated
using (
  exists (
    select 1 from public.restaurants r
    where r.id = avis_internes.id_restaurant
      and r.email_patron = auth.jwt() ->> 'email'
  )
)
with check (
  exists (
    select 1 from public.restaurants r
    where r.id = avis_internes.id_restaurant
      and r.email_patron = auth.jwt() ->> 'email'
  )
);

-- ✅ Terminé — Le bouton « Répondre » du dashboard fonctionne maintenant.
