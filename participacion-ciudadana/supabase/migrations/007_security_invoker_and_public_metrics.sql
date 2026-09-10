-- Endurecimiento adicional del piloto: elimina vistas SECURITY DEFINER públicas,
-- corrige métricas de participación y cierra ejecución directa de funciones internas.
-- Requiere 001-006.

-- 1) Registro explícito de tablas deliberadamente no accesibles de forma directa.
drop policy if exists audit_events_no_direct_access on public.audit_events;
create policy audit_events_no_direct_access on public.audit_events
as restrictive for all to anon, authenticated
using (false) with check (false);

drop policy if exists ballot_votes_no_direct_access on public.ballot_votes;
create policy ballot_votes_no_direct_access on public.ballot_votes
as restrictive for all to anon, authenticated
using (false) with check (false);

revoke all on public.audit_events from anon, authenticated;
revoke all on public.ballot_votes from anon, authenticated;

-- 2) Métricas públicas de votación en tabla agregada: evita exponer elegibilidad o boletas.
create table if not exists public.ballot_public_metrics(
  ballot_id uuid primary key references public.ballots(id) on delete cascade,
  eligible_count bigint not null default 0,
  participant_count bigint not null default 0,
  vote_count bigint not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.ballot_public_metrics enable row level security;
drop policy if exists ballot_public_metrics_read on public.ballot_public_metrics;
create policy ballot_public_metrics_read on public.ballot_public_metrics
for select to anon, authenticated using (true);
grant select on public.ballot_public_metrics to anon, authenticated;

create or replace function public.refresh_ballot_public_metrics(p_ballot_id uuid)
returns void
language plpgsql
security definer
set search_path=public,pg_temp
as $$
begin
  insert into public.ballot_public_metrics(ballot_id,eligible_count,participant_count,vote_count,updated_at)
  values(
    p_ballot_id,
    (select count(*) from public.ballot_eligibility e where e.ballot_id=p_ballot_id and e.eligible),
    (select count(*) from public.ballot_eligibility e where e.ballot_id=p_ballot_id and e.voted_at is not null),
    (select count(*) from public.ballot_votes v where v.ballot_id=p_ballot_id),
    now()
  )
  on conflict(ballot_id) do update set
    eligible_count=excluded.eligible_count,
    participant_count=excluded.participant_count,
    vote_count=excluded.vote_count,
    updated_at=excluded.updated_at;
end;
$$;
revoke all on function public.refresh_ballot_public_metrics(uuid) from public,anon,authenticated;

create or replace function public.refresh_ballot_public_metrics_trigger()
returns trigger
language plpgsql
security definer
set search_path=public,pg_temp
as $$
begin
  perform public.refresh_ballot_public_metrics(coalesce(new.ballot_id,old.ballot_id));
  return coalesce(new,old);
end;
$$;
revoke all on function public.refresh_ballot_public_metrics_trigger() from public,anon,authenticated;

drop trigger if exists ballot_eligibility_refresh_public_metrics on public.ballot_eligibility;
create trigger ballot_eligibility_refresh_public_metrics
after insert or update or delete on public.ballot_eligibility
for each row execute function public.refresh_ballot_public_metrics_trigger();

drop trigger if exists ballot_votes_refresh_public_metrics on public.ballot_votes;
create trigger ballot_votes_refresh_public_metrics
after insert or update or delete on public.ballot_votes
for each row execute function public.refresh_ballot_public_metrics_trigger();

insert into public.ballot_public_metrics(ballot_id,eligible_count,participant_count,vote_count)
select
  b.id,
  (select count(*) from public.ballot_eligibility e where e.ballot_id=b.id and e.eligible),
  (select count(*) from public.ballot_eligibility e where e.ballot_id=b.id and e.voted_at is not null),
  (select count(*) from public.ballot_votes v where v.ballot_id=b.id)
from public.ballots b
on conflict(ballot_id) do update set
  eligible_count=excluded.eligible_count,
  participant_count=excluded.participant_count,
  vote_count=excluded.vote_count,
  updated_at=now();

-- 3) Vistas públicas como SECURITY INVOKER.
drop view if exists public.public_ballot_integrity;
drop view if exists public.ballot_turnout;

create view public.ballot_turnout
with (security_invoker=true)
as
select b.id ballot_id,b.title,b.method,
       coalesce(m.eligible_count,0) eligible_count,
       coalesce(m.participant_count,0) participant_count,
       coalesce(m.vote_count,0) vote_count
from public.ballots b
left join public.ballot_public_metrics m on m.ballot_id=b.id
where b.status in ('open','closed','audited','certified');

grant select on public.ballot_turnout to anon,authenticated;

create view public.public_ballot_integrity
with (security_invoker=true)
as
select
  b.id as ballot_id,
  b.title,
  b.method,
  b.status,
  b.rules_hash,
  b.options_hash,
  b.result_hash,
  b.software_commit,
  b.integrity_level,
  coalesce(m.eligible_count,0) eligible_count,
  coalesce(m.participant_count,0) participant_count,
  coalesce(m.vote_count,0) vote_count
from public.ballots b
left join public.ballot_public_metrics m on m.ballot_id=b.id
where b.status in ('open','closed','audited','certified');

grant select on public.public_ballot_integrity to anon,authenticated;

-- 4) Vistas sanitizadas: RLS + privilegios por columna + SECURITY INVOKER.
drop policy if exists moderation_actions_public_safe_read on public.moderation_actions;
create policy moderation_actions_public_safe_read on public.moderation_actions
for select to anon,authenticated using(true);
revoke all on public.moderation_actions from anon,authenticated;
grant select(id,contribution_id,proposal_id,action,rule_code,rationale,evidence_hash,appeal_status,created_at)
  on public.moderation_actions to anon,authenticated;
drop view if exists public.public_moderation_log;
create view public.public_moderation_log
with (security_invoker=true)
as
select id,contribution_id,proposal_id,action,rule_code,rationale,evidence_hash,appeal_status,created_at
from public.moderation_actions;
grant select on public.public_moderation_log to anon,authenticated;

drop policy if exists incidents_public_safe_read on public.participation_incidents;
create policy incidents_public_safe_read on public.participation_incidents
for select to anon,authenticated using(true);
revoke all on public.participation_incidents from anon,authenticated;
grant select(id,process_id,ballot_id,severity,category,public_summary,status,affects_result,resolution_public,opened_at,resolved_at)
  on public.participation_incidents to anon,authenticated;
drop view if exists public.public_participation_incidents;
create view public.public_participation_incidents
with (security_invoker=true)
as
select id,process_id,ballot_id,severity,category,public_summary,status,affects_result,resolution_public,opened_at,resolved_at
from public.participation_incidents;
grant select on public.public_participation_incidents to anon,authenticated;

drop policy if exists governance_roles_public_safe_read on public.governance_roles;
create policy governance_roles_public_safe_read on public.governance_roles
for select to anon,authenticated using(true);
revoke all on public.governance_roles from anon,authenticated;
grant select(role,institution_id,process_id,active,expires_at)
  on public.governance_roles to anon,authenticated;
drop view if exists public.public_governance_summary;
create view public.public_governance_summary
with (security_invoker=true)
as
select role,institution_id,process_id,
       count(*) filter(where active and (expires_at is null or expires_at>now())) as active_assignments
from public.governance_roles
group by role,institution_id,process_id;
grant select on public.public_governance_summary to anon,authenticated;

-- Evaluaciones ya son públicamente legibles por política; restringimos columnas sensibles.
revoke all on public.technical_evaluations from anon,authenticated;
grant select(id,proposal_id,dimension,assessment,rating,evidence_url,conflict_declared,created_at)
  on public.technical_evaluations to anon,authenticated;
drop view if exists public.public_technical_evaluations;
create view public.public_technical_evaluations
with (security_invoker=true)
as
select id,proposal_id,dimension,assessment,rating,evidence_url,conflict_declared,created_at
from public.technical_evaluations;
grant select on public.public_technical_evaluations to anon,authenticated;

-- 5) Search path fijo en utilidades y triggers.
alter function public.hash_jsonb(jsonb) set search_path=public,pg_temp;
alter function public.prevent_frozen_ballot_change() set search_path=public,pg_temp;
alter function public.prevent_frozen_option_change() set search_path=public,pg_temp;
alter function public.protect_append_only() set search_path=public,pg_temp;

-- 6) Funciones internas: no deben ser RPC invocables por clientes.
revoke all on function public.handle_new_citizen() from public,anon,authenticated;
revoke all on function public.log_public_integrity_event() from public,anon,authenticated;
revoke all on function public.validate_ballot_selection(uuid,jsonb) from public,anon,authenticated;
revoke all on function public.has_governance_role(text[],uuid,uuid) from public,anon;
grant execute on function public.has_governance_role(text[],uuid,uuid) to authenticated;

-- Las funciones futuras dejan de ser ejecutables por PUBLIC por defecto.
alter default privileges for role postgres in schema public revoke execute on functions from public;
