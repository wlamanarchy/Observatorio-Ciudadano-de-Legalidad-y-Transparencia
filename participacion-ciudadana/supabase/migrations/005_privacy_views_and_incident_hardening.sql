-- Protege columnas internas y expone únicamente vistas públicas seguras.

-- Incidentes: el detalle técnico interno no debe exponerse al público.
drop policy if exists incidents_public_read on public.participation_incidents;

create policy incidents_authorized_read on public.participation_incidents
for select to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor','data_steward'],null,process_id));

revoke all on public.participation_incidents from anon;

create or replace view public.public_participation_incidents as
select
  id,
  process_id,
  ballot_id,
  severity,
  category,
  public_summary,
  status,
  affects_result,
  resolution_public,
  opened_at,
  resolved_at
from public.participation_incidents;

grant select on public.public_participation_incidents to anon,authenticated;

-- El registro de roles no se publica con UUID de usuario.
create or replace view public.public_governance_summary as
select
  role,
  institution_id,
  process_id,
  count(*) filter(where active and (expires_at is null or expires_at>now())) as active_assignments
from public.governance_roles
group by role,institution_id,process_id;

grant select on public.public_governance_summary to anon,authenticated;

-- Evaluaciones técnicas: vista pública sin identificador interno del evaluador.
create or replace view public.public_technical_evaluations as
select
  id,
  proposal_id,
  dimension,
  assessment,
  rating,
  evidence_url,
  conflict_declared,
  created_at
from public.technical_evaluations;

grant select on public.public_technical_evaluations to anon,authenticated;

-- Los recibos individuales nunca se exponen mediante vista pública.
-- Solo conteos y hashes agregados/certificados se publican.
revoke all on public.ballot_votes from anon,authenticated;

-- Los eventos de integridad contienen únicamente hashes y metadatos públicos mínimos.
-- Se mantiene lectura pública para permitir auditoría independiente.
revoke insert,update,delete on public.integrity_events from anon,authenticated;
revoke insert,update,delete on public.transparency_checkpoints from anon,authenticated;
