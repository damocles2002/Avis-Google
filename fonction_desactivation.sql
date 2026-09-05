-- ============================================================
-- VERROU SERVEUR : blocage des avis (anti-contournement)
-- 1. Restaurant désactivé par l'admin
-- 2. Essai gratuit expiré (pas encore abonné)
-- ============================================================

CREATE OR REPLACE FUNCTION bloquer_avis_desactive() RETURNS trigger AS $$
begin
  -- 1. Restaurant désactivé
  if exists (select 1 from public.restaurants r where r.id = new.id_restaurant and r.desactive = true) then
    raise exception 'Ce restaurant est desactive';
  end if;
  -- 2. Essai gratuit expiré
  if exists (select 1 from public.restaurants r where r.id = new.id_restaurant
             and r.abonnement_statut = 'essai'
             and r.abonnement_expire_le is not null
             and r.abonnement_expire_le < now()) then
    raise exception 'Essai expire : abonnez-vous pour continuer';
  end if;
  return new;
end;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bloquer_avis_desactive_trigger ON public.avis_internes;
CREATE TRIGGER bloquer_avis_desactive_trigger
BEFORE INSERT ON public.avis_internes
FOR EACH ROW EXECUTE FUNCTION bloquer_avis_desactive();
