-- ============================================================
-- 🔒 SÉCURITÉ DAMAVIS — Script à coller dans Supabase
-- Où : Supabase > SQL Editor > Nouvelle requête > coller > Run
-- ============================================================
-- Ce script verrouille tes données pour que :
--   ✅ Le public puisse donner un avis (mais PAS lire les avis des autres)
--   ✅ Le restaurant voie SEULEMENT ses propres avis
--   ✅ Toi (admin) voie et gère tout
--   ✅ Personne ne puisse voir les emails ou les avis négatifs confidentiels
-- ============================================================

-- ── ÉTAPE 1 : Activer la protection sur les 2 tables ──
alter table public.restaurants enable row level security;
alter table public.avis_internes enable row level security;

-- ── ÉTAPE 2 : Supprimer toutes les anciennes règles ouvertes ──
do $$
declare
  pol record;
begin
  for pol in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in ('restaurants', 'avis_internes')
  loop
    execute format('drop policy if exists %I on public.%I', pol.policyname, pol.tablename);
  end loop;
end $$;

-- ── ÉTAPE 3 : Vue publique (le nom + lien Google, SANS les emails) ──
-- La page d'avis (index.html) lit uniquement cette vue.
create or replace view public.restaurants_public as
select id, nom, google_maps_url, seuil_google, desactive
from public.restaurants;

grant select on public.restaurants_public to anon, authenticated;

-- ── ÉTAPE 4 : Règles sur la table "restaurants" ──

-- Le proprio (restaurant connecté) lit SA fiche
create policy "resto_proprio_select" on public.restaurants
for select to authenticated
using (email_patron = auth.jwt() ->> 'email');

-- L'admin lit toutes les fiches
create policy "resto_admin_select" on public.restaurants
for select to authenticated
using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- L'admin crée un restaurant
create policy "resto_admin_insert" on public.restaurants
for insert to authenticated
with check (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- L'admin modifie (ex: désactiver un compte)
create policy "resto_admin_update" on public.restaurants
for update to authenticated
using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com')
with check (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- L'admin supprime
create policy "resto_admin_delete" on public.restaurants
for delete to authenticated
using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- ── ÉTAPE 5 : Règles sur la table "avis_internes" ──

-- Le public PEUT déposer un avis (mais PAS lire)
create policy "avis_public_insert" on public.avis_internes
for insert to anon, authenticated
with check (true);

-- Le proprio lit SES avis uniquement
create policy "avis_proprio_select" on public.avis_internes
for select to authenticated
using (
  exists (
    select 1 from public.restaurants r
    where r.id = avis_internes.id_restaurant
      and r.email_patron = auth.jwt() ->> 'email'
  )
);

-- L'admin lit tous les avis
create policy "avis_admin_select" on public.avis_internes
for select to authenticated
using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- L'admin modifie les avis
create policy "avis_admin_update" on public.avis_internes
for update to authenticated
using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- L'admin supprime les avis
create policy "avis_admin_delete" on public.avis_internes
for delete to authenticated
using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- ============================================================
-- ✅ TERMINÉ — Une fois exécuté, vérifie :
--    1. Le public ne peut plus lire les avis (testé par nous)
--    2. Le public peut toujours déposer un avis
--    3. Le restaurant voit ses avis en se connectant
-- ============================================================

-- Recharge le schéma pour que la vue publique soit visible immédiatement
notify pgrst, 'reload schema';
