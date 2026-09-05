-- ============================================================
-- 💾 SAUVEGARDE RÉELLE — Script à coller dans Supabase
-- Où : Supabase > SQL Editor > Nouvelle requête > coller > Run
-- ============================================================
-- Permet de sauvegarder le nom + liens + couleur du resto en ligne
-- (au lieu du navigateur uniquement).

-- Ajouter une colonne "settings" (JSON) à la table restaurants
alter table public.restaurants
add column if not exists settings jsonb default '{}'::jsonb;

-- ✅ Terminé — Les réglages du resto sont maintenant sauvegardés en ligne.
