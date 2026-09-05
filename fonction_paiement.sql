-- ============================================================
-- 💳 SYSTÈME DE PAIEMENT — Structure complète (référence)
-- ============================================================

-- 1. Table "parametres" : les réglages de paiement modifiables par l'admin
create table if not exists public.parametres (
  cle text primary key,
  valeur text
);

insert into public.parametres (cle, valeur) values
  ('prix_euro', '25'),
  ('prix_xaf', '10000'),
  ('essai_jours', '14'),
  ('paddle_actif', 'true'),
  ('cinpay_actif', 'false'),
  ('lien_paddle', ''),
  ('lien_cinpay', '')
on conflict (cle) do nothing;

-- 2. Colonnes d'abonnement dans la table restaurants
alter table public.restaurants
  add column if not exists abonnement_statut text default 'essai',
  add column if not exists abonnement_expire_le timestamp with time zone,
  add column if not exists abonnement_fournisseur text;

-- 3. Sécurité : seul l'admin peut lire/écrire les parametres
alter table public.parametres enable row level security;
create policy "param_admin_select" on public.parametres for select using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');
create policy "param_admin_insert" on public.parametres for insert with check (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');
create policy "param_admin_update" on public.parametres for update using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');
create policy "param_admin_delete" on public.parametres for delete using (auth.jwt() ->> 'email' = 'ngongangdjomo@gmail.com');

-- 4. Vue publique : prix + essai lisibles par tous, SANS les clés sensibles
create or replace view public.parametres_public as
select cle, valeur from public.parametres
where cle in ('prix_euro', 'prix_xaf', 'essai_jours', 'paddle_actif', 'cinpay_actif');

-- 5. Trigger : initialiser l'essai gratuit à la création d'un restaurant
create or replace function public.init_abonnement() returns trigger as $$
declare jours integer;
begin
  select coalesce((select valeur::integer from public.parametres where cle='essai_jours'), 14) into jours;
  if new.abonnement_expire_le is null then
    new.abonnement_expire_le = now() + (jours || ' days')::interval;
  end if;
  return new;
end; $$ language plpgsql security definer;

drop trigger if exists init_abonnement_trigger on public.restaurants;
create trigger init_abonnement_trigger before insert on public.restaurants
for each row execute function public.init_abonnement();

-- 6. Trigger : empêcher un restaurant de modifier son propre abonnement
--    (seuls l'admin ou le système peuvent changer le statut)
create or replace function public.proteger_abonnement() returns trigger as $$
begin
  if auth.jwt() ->> 'email' is not null
     and coalesce(auth.jwt() ->> 'email','') <> 'ngongangdjomo@gmail.com' then
    if new.abonnement_statut is distinct from old.abonnement_statut
       or new.abonnement_expire_le is distinct from old.abonnement_expire_le
       or new.abonnement_fournisseur is distinct from old.abonnement_fournisseur then
      raise exception 'Vous ne pouvez pas modifier votre abonnement';
    end if;
  end if;
  return new;
end; $$ language plpgsql security definer;

drop trigger if exists proteger_abonnement_trigger on public.restaurants;
create trigger proteger_abonnement_trigger before update on public.restaurants
for each row execute function public.proteger_abonnement();

-- 7. Migration : initialiser l'essai des restaurants existants
update public.restaurants set abonnement_expire_le = now() + interval '14 days' where abonnement_expire_le is null;
