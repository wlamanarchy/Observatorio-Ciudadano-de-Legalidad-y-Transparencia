-- Guardarraíl de calidad de publicación del Observatorio.
-- Una ficha no puede hacerse pública solo cambiando un booleano.

create or replace function public.enforce_finding_publication_quality()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.published = true then
    if new.verification_status <> 'documentado' then
      raise exception 'Publicación bloqueada: la ficha debe estar DOCUMENTADA';
    end if;
    if new.replica_status not in ('respondido','no_aplica') then
      raise exception 'Publicación bloqueada: la réplica debe estar respondida o motivadamente marcada como no aplicable';
    end if;
    if not exists (
      select 1 from public.sources s
      where s.finding_id = new.id
        and s.is_primary = true
        and s.verified = true
    ) then
      raise exception 'Publicación bloqueada: falta una fuente primaria verificada';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_finding_publication_quality() from public, anon, authenticated;
drop trigger if exists findings_publication_quality on public.findings;
create trigger findings_publication_quality
before insert or update of published, verification_status, replica_status on public.findings
for each row execute function public.enforce_finding_publication_quality();
