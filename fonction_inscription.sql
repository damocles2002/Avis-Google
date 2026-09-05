-- ============================================================
-- INSCRIPTION AUTONOME (self-service)
-- ============================================================

-- 1. Policy RLS : le proprio peut créer SON propre restaurant
--    (condition : email_patron = email de l'utilisateur connecté)
DROP POLICY IF EXISTS "resto_proprio_insert" ON public.restaurants;
CREATE POLICY "resto_proprio_insert" ON public.restaurants
FOR INSERT WITH CHECK (email_patron = (auth.jwt() ->> 'email'::text));

-- NOTE : le mail de bienvenue est envoyé DIRECTEMENT depuis login.html
-- (fonction handleSignup → fetch vers l'Edge Function "notifier" avec
-- type="bienvenue"). Pas de trigger SQL ici : l'appel direct est plus
-- fiable et permet de confirmer l'envoi.
