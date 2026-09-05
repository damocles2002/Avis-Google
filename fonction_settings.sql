-- ============================================================
-- 💾 SAUVEGARDE RÉELLE — Script à coller dans Supabase
-- Où : Supabase > SQL Editor > Nouvelle requête > coller > Run
-- ============================================================
-- Permet de sauvegarder le nom + liens + couleur du resto en ligne
-- (au lieu du navigateur uniquement).

-- Étape 1 : Ajouter une colonne "settings" (JSON) à la table restaurants
alter table public.restaurants
add column if not exists settings jsonb default '{}'::jsonb;

-- Étape 2 : Autoriser le restaurant à mettre à jour SA propre fiche
-- (pour enregistrer ses réglages). Sans ça, la sauvegarde échoue.
drop policy if exists "resto_proprio_update" on public.restaurants;
create policy "resto_proprio_update" on public.restaurants
for update to authenticated
using (email_patron = auth.jwt() ->> 'email')
with check (email_patron = auth.jwt() ->> 'email');

-- ✅ Terminé — Les réglages du resto sont sauvegardés en ligne.
