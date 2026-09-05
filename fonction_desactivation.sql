-- ============================================================
-- 🚫 DÉSACTIVATION — Verrou serveur (référence)
-- Empêche le dépôt d'avis sur un restaurant désactivé,
-- même si quelqu'un contourne la page web (attaque directe par API).
-- ============================================================

create or replace function public.bloquer_avis_desactive() returns trigger as $$
begin
  if exists (select 1 from public.restaurants r where r.id = new.id_restaurant and r.desactive = true) then
    raise exception 'Ce restaurant est desactive';
  end if;
  return new;
end; $$ language plpgsql security definer;

drop trigger if exists bloquer_avis_desactive_trigger on public.avis_internes;
create trigger bloquer_avis_desactive_trigger before insert on public.avis_internes
for each row execute function public.bloquer_avis_desactive();
