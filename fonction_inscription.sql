-- ============================================================
-- INSCRIPTION AUTONOME (self-service)
-- Permet au restaurant de créer son propre compte depuis login.html
-- et reçoit un mail de bienvenue.
-- ============================================================

-- 1. Policy RLS : le proprio peut créer SON propre restaurant
--    (condition : email_patron = email de l'utilisateur connecté)
DROP POLICY IF EXISTS "resto_proprio_insert" ON public.restaurants;
CREATE POLICY "resto_proprio_insert" ON public.restaurants
FOR INSERT WITH CHECK (email_patron = (auth.jwt() ->> 'email'::text));

-- 2. Fonction + trigger : envoie un mail de bienvenue à l'inscription
--    (appelle l'Edge Function "notifier" avec type=bienvenue)
CREATE OR REPLACE FUNCTION notifier_bienvenue() RETURNS trigger AS $$
begin
  perform net.http_post(
    url := 'https://urpfgiaocxfnyfdoiapf.supabase.co/functions/v1/notifier',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer [ANON_KEY]'  -- remplacer par SB_KEY de js/config.js
    ),
    body := jsonb_build_object('type', 'bienvenue', 'record', row_to_json(new))
  );
  return new;
end;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS resto_bienvenue_trigger ON public.restaurants;
CREATE TRIGGER resto_bienvenue_trigger
AFTER INSERT ON public.restaurants
FOR EACH ROW EXECUTE FUNCTION notifier_bienvenue();
