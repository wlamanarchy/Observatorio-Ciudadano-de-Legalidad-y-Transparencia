-- Procedencia diagnóstica, reglas congeladas, consenso y registro criptográfico.
-- Esta migración no almacena datos personales ni selecciones de voto en blockchain.

create table if not exists public.diagnostic_sources(
  id uuid primary key default gen_random_uuid(),
  diagnostic_id uuid not null references public.diagnostics(id) on delete cascade,
  source_system text not null,
  source_record_id text,
  source_url text not null,
  source_version text,
  source_hash text not null,
  source_published_at timestamptz,
  retrieved_at timestamptz not null default now(),
  integrity_status text not null default 'pending' check(integrity_status in ('pending','verified','discrepancy')),
  public_payload jsonb not null default '{}'::jsonb,
  imported_by uuid references auth.users(id),
  unique(diagnostic_id, source_system, source_record_id, source_hash)
);

create index if not exists diagnostic_sources_diagnostic_idx
  on public.diagnostic_sources(diagnostic_id, retrieved_at desc);

create table if not exists public.process_rule_snapshots(
  id uuid primary key default gen_random_uuid(),
  process_id uuid not null references public.participation_processes(id) on delete cascade,
  snapshot_no integer not null,
  rules jsonb not null,
  rules_hash text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(process_id, snapshot_no),
  unique(process_id, rules_hash)
);

create table if not exists public.consensus_rules(
  process_id uuid primary key references public.participation_processes(id) on delete cascade,
  min_participants bigint,
  min_turnout_pct numeric(6,3),
  min_support_pct numeric(6,3),
  min_territories integer,
  min_territory_support_pct numeric(6,3),
  require_deliberation boolean not null default true,
  require_technical_evaluation boolean not null default true,
  require_no_critical_incidents boolean not null default true,
  additional_rules jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  rules_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(min_turnout_pct is null or (min_turnout_pct between 0 and 100)),
  check(min_support_pct is null or (min_support_pct between 0 and 100)),
  check(min_territory_support_pct is null or (min_territory_support_pct between 0 and 100))
);

create table if not exists public.consensus_assessments(
  id uuid primary key default gen_random_uuid(),
  ballot_id uuid not null references public.ballots(id) on delete cascade,
  qualification text not null check(qualification in ('aporte_emergente','apoyo_relevante','prioridad_participativa','prioridad_territorial_amplia','consenso_amplio','decision_formal')),
  metrics jsonb not null,
  methodology_hash text not null,
  result_hash text not null,
  assessed_by uuid references auth.users(id),
  assessed_at timestamptz not null default now()
);

alter table public.ballots add column if not exists rules_hash text;
alter table public.ballots add column if not exists options_hash text;
alter table public.ballots add column if not exists result_hash text;
alter table public.ballots add column if not exists software_commit text;
alter table public.ballots add column if not exists integrity_level text not null default 'pilot'
  check(integrity_level in ('pilot','enhanced','independent_audit','formal_mechanism'));

create table if not exists public.integrity_events(
  id bigint generated always as identity primary key,
  previous_hash text,
  event_hash text not null unique,
  event_type text not null,
  object_type text not null,
  object_id uuid,
  payload_hash text not null,
  public_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default clock_timestamp()
);

create table if not exists public.transparency_checkpoints(
  id uuid primary key default gen_random_uuid(),
  first_event_id bigint references public.integrity_events(id),
  last_event_id bigint references public.integrity_events(id),
  chain_head_hash text not null,
  receipts_root_hash text,
  rules_hash text,
  results_hash text,
  software_commit text,
  anchor_type text,
  anchor_network text,
  anchor_reference text,
  anchored_at timestamptz,
  created_at timestamptz not null default now(),
  check(last_event_id is null or first_event_id is null or last_event_id >= first_event_id)
);

create or replace function public.hash_jsonb(p_value jsonb)
returns text
language sql
immutable
strict
as $$
  select encode(digest(convert_to(p_value::text,'UTF8'),'sha256'),'hex');
$$;

create or replace function public.lock_process_rules(p_process_id uuid)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  p public.participation_processes%rowtype;
  v_hash text;
  v_no integer;
begin
  select * into p from public.participation_processes where id=p_process_id for update;
  if not found then raise exception 'Proceso no encontrado'; end if;
  if p.rules_locked_at is not null then raise exception 'Las reglas ya fueron congeladas'; end if;
  v_hash := public.hash_jsonb(p.rules);
  select coalesce(max(snapshot_no),0)+1 into v_no from public.process_rule_snapshots where process_id=p_process_id;
  insert into public.process_rule_snapshots(process_id,snapshot_no,rules,rules_hash,created_by)
  values(p_process_id,v_no,p.rules,v_hash,auth.uid());
  update public.participation_processes set rules_locked_at=now() where id=p_process_id;
  return v_hash;
end;
$$;
revoke all on function public.lock_process_rules(uuid) from public, anon;
grant execute on function public.lock_process_rules(uuid) to authenticated;

create or replace function public.freeze_ballot(p_ballot_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.ballots%rowtype;
  v_options jsonb;
  v_rules_hash text;
  v_options_hash text;
begin
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found then raise exception 'Votación no encontrada'; end if;
  if b.status <> 'draft' then raise exception 'Solo se puede congelar una votación en borrador'; end if;

  select jsonb_agg(
    jsonb_build_object(
      'id',o.id,
      'proposal_id',o.proposal_id,
      'label',o.label,
      'sort_order',o.sort_order
    ) order by o.sort_order,o.id
  ) into v_options
  from public.ballot_options o
  where o.ballot_id=p_ballot_id;

  if v_options is null then raise exception 'La votación no tiene opciones'; end if;
  v_rules_hash := public.hash_jsonb(b.rules);
  v_options_hash := public.hash_jsonb(v_options);

  update public.ballots
    set rules_hash=v_rules_hash, options_hash=v_options_hash
    where id=p_ballot_id;

  return jsonb_build_object('rules_hash',v_rules_hash,'options_hash',v_options_hash);
end;
$$;
revoke all on function public.freeze_ballot(uuid) from public, anon;
grant execute on function public.freeze_ballot(uuid) to authenticated;

create or replace function public.prevent_frozen_ballot_change()
returns trigger
language plpgsql
as $$
begin
  if old.status <> 'draft' and (
    new.rules is distinct from old.rules or
    new.method is distinct from old.method or
    new.verification_required is distinct from old.verification_required or
    new.opens_at is distinct from old.opens_at or
    new.closes_at is distinct from old.closes_at
  ) then
    raise exception 'Reglas congeladas: la votación debe cerrarse/anularse y versionarse para cambiar su configuración';
  end if;
  return new;
end;
$$;

drop trigger if exists ballots_prevent_frozen_change on public.ballots;
create trigger ballots_prevent_frozen_change
before update on public.ballots
for each row execute function public.prevent_frozen_ballot_change();

create or replace function public.prevent_frozen_option_change()
returns trigger
language plpgsql
as $$
declare
  v_ballot_id uuid;
  v_status text;
begin
  v_ballot_id := coalesce(new.ballot_id,old.ballot_id);
  select status into v_status from public.ballots where id=v_ballot_id;
  if v_status is distinct from 'draft' then
    raise exception 'Las opciones no pueden modificarse después de abrir/cerrar una votación';
  end if;
  return coalesce(new,old);
end;
$$;

drop trigger if exists ballot_options_prevent_frozen_change on public.ballot_options;
create trigger ballot_options_prevent_frozen_change
before insert or update or delete on public.ballot_options
for each row execute function public.prevent_frozen_option_change();

create or replace function public.append_integrity_event(
  p_event_type text,
  p_object_type text,
  p_object_id uuid,
  p_payload_hash text,
  p_public_metadata jsonb default '{}'::jsonb
)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  v_previous text;
  v_now timestamptz := clock_timestamp();
  v_hash text;
begin
  perform pg_advisory_xact_lock(741852963);
  select event_hash into v_previous from public.integrity_events order by id desc limit 1;
  v_hash := encode(digest(convert_to(
    coalesce(v_previous,'GENESIS') || '|' || p_event_type || '|' || p_object_type || '|' ||
    coalesce(p_object_id::text,'') || '|' || p_payload_hash || '|' || v_now::text,
    'UTF8'),'sha256'),'hex');
  insert into public.integrity_events(previous_hash,event_hash,event_type,object_type,object_id,payload_hash,public_metadata,created_at)
  values(v_previous,v_hash,p_event_type,p_object_type,p_object_id,p_payload_hash,coalesce(p_public_metadata,'{}'::jsonb),v_now);
  return v_hash;
end;
$$;
revoke all on function public.append_integrity_event(text,text,uuid,text,jsonb) from public, anon, authenticated;

create or replace function public.log_public_integrity_event()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  v_row jsonb;
  v_id uuid;
begin
  v_row := case when tg_op='DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_id := case when tg_op='DELETE' then old.id else new.id end;
  perform public.append_integrity_event(
    lower(tg_op),
    tg_table_name,
    v_id,
    public.hash_jsonb(v_row),
    jsonb_build_object('schema',tg_table_schema)
  );
  return coalesce(new,old);
end;
$$;

-- Solo objetos públicos y decisorios: se guarda el hash de la fila, no su contenido.
drop trigger if exists proposals_integrity_log on public.proposals;
create trigger proposals_integrity_log after insert or update or delete on public.proposals
for each row execute function public.log_public_integrity_event();

drop trigger if exists processes_integrity_log on public.participation_processes;
create trigger processes_integrity_log after insert or update or delete on public.participation_processes
for each row execute function public.log_public_integrity_event();

drop trigger if exists ballots_integrity_log on public.ballots;
create trigger ballots_integrity_log after insert or update or delete on public.ballots
for each row execute function public.log_public_integrity_event();

drop trigger if exists responses_integrity_log on public.institutional_responses;
create trigger responses_integrity_log after insert or update or delete on public.institutional_responses
for each row execute function public.log_public_integrity_event();

create or replace function public.protect_append_only()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Registro append-only: no se permite modificar o borrar eventos históricos';
end;
$$;

drop trigger if exists integrity_events_append_only on public.integrity_events;
create trigger integrity_events_append_only before update or delete on public.integrity_events
for each row execute function public.protect_append_only();

drop trigger if exists transparency_checkpoints_append_only on public.transparency_checkpoints;
create trigger transparency_checkpoints_append_only before update or delete on public.transparency_checkpoints
for each row execute function public.protect_append_only();

alter table public.diagnostic_sources enable row level security;
alter table public.process_rule_snapshots enable row level security;
alter table public.consensus_rules enable row level security;
alter table public.consensus_assessments enable row level security;
alter table public.integrity_events enable row level security;
alter table public.transparency_checkpoints enable row level security;

create policy diagnostic_sources_public_read on public.diagnostic_sources for select using(true);
create policy process_rule_snapshots_public_read on public.process_rule_snapshots for select using(true);
create policy consensus_rules_public_read on public.consensus_rules for select using(published_at is not null);
create policy consensus_assessments_public_read on public.consensus_assessments for select using(true);
create policy integrity_events_public_read on public.integrity_events for select using(true);
create policy transparency_checkpoints_public_read on public.transparency_checkpoints for select using(true);

create or replace view public.public_ballot_integrity as
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
  t.eligible_count,
  t.participant_count,
  t.vote_count
from public.ballots b
left join public.ballot_turnout t on t.ballot_id=b.id
where b.status in ('open','closed','audited','certified');

grant select on public.public_ballot_integrity to anon,authenticated;
