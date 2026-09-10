-- Gobernanza, moderación, incidentes e integridad de selección.
-- Requiere 001, 002 y 003.

create table if not exists public.governance_roles(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check(role in (
    'platform_admin','methodology_admin','institution_admin','process_facilitator',
    'moderator','technical_evaluator','independent_auditor','data_steward'
  )),
  institution_id uuid references public.institutions(id) on delete cascade,
  process_id uuid references public.participation_processes(id) on delete cascade,
  active boolean not null default true,
  expires_at timestamptz,
  assigned_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  check(not (institution_id is not null and process_id is not null))
);

create index if not exists governance_roles_user_idx on public.governance_roles(user_id,active);
create index if not exists governance_roles_process_idx on public.governance_roles(process_id,role,active);
create index if not exists governance_roles_institution_idx on public.governance_roles(institution_id,role,active);

create or replace function public.has_governance_role(
  p_roles text[],
  p_institution_id uuid default null,
  p_process_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1
    from public.governance_roles r
    where r.user_id=(select auth.uid())
      and r.active
      and (r.expires_at is null or r.expires_at>now())
      and (
        r.role='platform_admin'
        or (
          r.role=any(p_roles)
          and (
            (r.process_id is null and r.institution_id is null)
            or (p_process_id is not null and r.process_id=p_process_id)
            or (p_institution_id is not null and r.institution_id=p_institution_id)
            or (
              p_process_id is not null and r.institution_id is not null and exists(
                select 1 from public.participation_processes p
                where p.id=p_process_id and p.institution_id=r.institution_id
              )
            )
          )
        )
      )
  );
$$;

grant execute on function public.has_governance_role(text[],uuid,uuid) to authenticated;
revoke execute on function public.has_governance_role(text[],uuid,uuid) from anon;

alter table public.governance_roles enable row level security;
create policy governance_roles_self_read on public.governance_roles
for select to authenticated
using(user_id=(select auth.uid()) or public.has_governance_role(array['platform_admin']));

create policy governance_roles_platform_admin_all on public.governance_roles
for all to authenticated
using(public.has_governance_role(array['platform_admin']))
with check(public.has_governance_role(array['platform_admin']));

-- Escritura institucional/procesal. Las políticas de lectura públicas de 002 se conservan.
create policy processes_governance_insert on public.participation_processes
for insert to authenticated
with check(public.has_governance_role(array['platform_admin','methodology_admin','institution_admin'],institution_id,null));

create policy processes_governance_update on public.participation_processes
for update to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],institution_id,id))
with check(public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],institution_id,id));

create policy diagnostics_governance_insert on public.diagnostics
for insert to authenticated
with check(public.has_governance_role(array['platform_admin','institution_admin','process_facilitator'],null,process_id));

create policy diagnostics_governance_update on public.diagnostics
for update to authenticated
using(public.has_governance_role(array['platform_admin','institution_admin','process_facilitator'],null,process_id))
with check(public.has_governance_role(array['platform_admin','institution_admin','process_facilitator'],null,process_id));

create policy ballots_governance_insert on public.ballots
for insert to authenticated
with check(public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,process_id));

create policy ballots_governance_update on public.ballots
for update to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,process_id))
with check(public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,process_id));

create policy ballot_options_governance_all on public.ballot_options
for all to authenticated
using(exists(
  select 1 from public.ballots b
  where b.id=ballot_options.ballot_id
    and public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,b.process_id)
))
with check(exists(
  select 1 from public.ballots b
  where b.id=ballot_options.ballot_id
    and public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,b.process_id)
));

create policy evaluations_authorized_insert on public.technical_evaluations
for insert to authenticated
with check(
  evaluator_id=(select auth.uid()) and exists(
    select 1 from public.proposals p
    where p.id=technical_evaluations.proposal_id
      and public.has_governance_role(array['platform_admin','technical_evaluator'],null,p.process_id)
  )
);

create policy responses_authorized_insert on public.institutional_responses
for insert to authenticated
with check(exists(
  select 1 from public.proposals p
  where p.id=institutional_responses.proposal_id
    and public.has_governance_role(array['platform_admin','institution_admin','process_facilitator'],institutional_responses.institution_id,p.process_id)
));

-- Moderación con motivación y apelación.
create table if not exists public.moderation_actions(
  id uuid primary key default gen_random_uuid(),
  contribution_id uuid references public.contributions(id) on delete set null,
  proposal_id uuid references public.proposals(id) on delete cascade,
  action text not null check(action in ('label','limit_visibility','hide','restore','lock_thread','unlock_thread')),
  rule_code text not null,
  rationale text not null,
  evidence_hash text,
  moderator_id uuid not null references auth.users(id),
  appeal_status text not null default 'not_appealed' check(appeal_status in ('not_appealed','pending','upheld','modified','revoked')),
  created_at timestamptz not null default now()
);

create table if not exists public.moderation_appeals(
  id uuid primary key default gen_random_uuid(),
  moderation_action_id uuid not null references public.moderation_actions(id) on delete cascade,
  appellant_id uuid not null references auth.users(id),
  grounds text not null,
  status text not null default 'pending' check(status in ('pending','upheld','modified','revoked')),
  decision_rationale text,
  decided_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);

alter table public.moderation_actions enable row level security;
alter table public.moderation_appeals enable row level security;

create policy moderation_actions_internal_read on public.moderation_actions
for select to authenticated
using(public.has_governance_role(array['platform_admin','moderator','independent_auditor'],null,null));

create policy moderation_actions_authorized_insert on public.moderation_actions
for insert to authenticated
with check(
  moderator_id=(select auth.uid())
  and public.has_governance_role(array['platform_admin','moderator'],null,null)
);

create policy moderation_appeals_owner_read on public.moderation_appeals
for select to authenticated
using(appellant_id=(select auth.uid()) or public.has_governance_role(array['platform_admin','moderator','independent_auditor'],null,null));

create policy moderation_appeals_owner_insert on public.moderation_appeals
for insert to authenticated
with check(appellant_id=(select auth.uid()));

create policy moderation_appeals_decision_update on public.moderation_appeals
for update to authenticated
using(public.has_governance_role(array['platform_admin','moderator','independent_auditor'],null,null))
with check(public.has_governance_role(array['platform_admin','moderator','independent_auditor'],null,null));

create or replace view public.public_moderation_log as
select id,contribution_id,proposal_id,action,rule_code,rationale,evidence_hash,appeal_status,created_at
from public.moderation_actions;
grant select on public.public_moderation_log to anon,authenticated;

-- Incidentes de integridad electoral/participativa.
create table if not exists public.participation_incidents(
  id uuid primary key default gen_random_uuid(),
  process_id uuid references public.participation_processes(id) on delete cascade,
  ballot_id uuid references public.ballots(id) on delete cascade,
  severity text not null check(severity in ('low','medium','high','critical')),
  category text not null,
  public_summary text not null,
  internal_detail jsonb not null default '{}'::jsonb,
  status text not null default 'open' check(status in ('open','investigating','mitigated','resolved','invalidated_process')),
  affects_result boolean not null default false,
  opened_by uuid references auth.users(id),
  resolved_by uuid references auth.users(id),
  resolution_public text,
  opened_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table public.participation_incidents enable row level security;
create policy incidents_public_read on public.participation_incidents
for select using(true);
create policy incidents_auditor_insert on public.participation_incidents
for insert to authenticated
with check(public.has_governance_role(array['platform_admin','independent_auditor','methodology_admin'],null,process_id));
create policy incidents_auditor_update on public.participation_incidents
for update to authenticated
using(public.has_governance_role(array['platform_admin','independent_auditor','methodology_admin'],null,process_id))
with check(public.has_governance_role(array['platform_admin','independent_auditor','methodology_admin'],null,process_id));

-- Registro de algoritmos y automatizaciones visibles.
create table if not exists public.algorithm_register(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  purpose text not null,
  affected_features text[] not null default '{}',
  input_categories text[] not null default '{}',
  ranking_or_decision_effect text not null,
  human_oversight text not null,
  appeal_mechanism text,
  source_repository text,
  source_commit text,
  risk_level text not null default 'low' check(risk_level in ('low','medium','high','prohibited')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.algorithm_register enable row level security;
create policy algorithm_register_public_read on public.algorithm_register for select using(true);
create policy algorithm_register_admin_all on public.algorithm_register
for all to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']))
with check(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']));

-- Paneles deliberativos representativos: datos públicos separados de membresía privada.
create table if not exists public.deliberative_panels(
  id uuid primary key default gen_random_uuid(),
  process_id uuid not null references public.participation_processes(id) on delete cascade,
  title text not null,
  selection_method text not null,
  target_size integer not null check(target_size>0),
  stratification_public jsonb not null default '{}'::jsonb,
  materials_url text,
  recommendations_url text,
  status text not null default 'design' check(status in ('design','recruiting','deliberating','completed','evaluated')),
  created_at timestamptz not null default now()
);

create table if not exists public.deliberative_panel_members_private(
  panel_id uuid not null references public.deliberative_panels(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  invited_at timestamptz,
  accepted_at timestamptz,
  primary key(panel_id,user_id)
);

alter table public.deliberative_panels enable row level security;
alter table public.deliberative_panel_members_private enable row level security;
create policy deliberative_panels_public_read on public.deliberative_panels for select using(true);
create policy panel_members_self_read on public.deliberative_panel_members_private
for select to authenticated
using(user_id=(select auth.uid()) or public.has_governance_role(array['platform_admin','process_facilitator','independent_auditor']));

-- Costos para presupuesto participativo.
alter table public.ballot_options add column if not exists estimated_cost numeric;

create or replace function public.validate_ballot_selection(p_ballot_id uuid,p_selection jsonb)
returns boolean
language plpgsql
stable
security definer
set search_path=public
as $$
declare
  v_method text;
  v_count integer;
  v_unique integer;
  v_sum numeric;
  v_budget numeric;
begin
  select method into v_method from public.ballots where id=p_ballot_id;
  if v_method is null then return false; end if;

  if v_method='yes_no' then
    return coalesce(p_selection->>'choice','') in ('yes','no','abstain');
  end if;

  if v_method='approval' then
    if jsonb_typeof(p_selection->'option_ids') <> 'array' then return false; end if;
    select count(*),count(distinct x) into v_count,v_unique
    from jsonb_array_elements_text(p_selection->'option_ids') x;
    if v_count<1 or v_count<>v_unique then return false; end if;
    return not exists(
      select 1 from jsonb_array_elements_text(p_selection->'option_ids') x
      where not exists(select 1 from public.ballot_options o where o.ballot_id=p_ballot_id and o.id::text=x)
    );
  end if;

  if v_method='ranked' then
    if jsonb_typeof(p_selection->'ranking') <> 'array' then return false; end if;
    select count(*),count(distinct x) into v_count,v_unique
    from jsonb_array_elements_text(p_selection->'ranking') x;
    if v_count<2 or v_count<>v_unique then return false; end if;
    return not exists(
      select 1 from jsonb_array_elements_text(p_selection->'ranking') x
      where not exists(select 1 from public.ballot_options o where o.ballot_id=p_ballot_id and o.id::text=x)
    );
  end if;

  if v_method='points100' then
    if jsonb_typeof(p_selection->'points') <> 'object' then return false; end if;
    select coalesce(sum(value::numeric),0) into v_sum from jsonb_each_text(p_selection->'points');
    if v_sum<>100 then return false; end if;
    return not exists(
      select 1 from jsonb_each_text(p_selection->'points') e
      where e.value !~ '^[0-9]+$'
         or e.value::numeric<0
         or not exists(select 1 from public.ballot_options o where o.ballot_id=p_ballot_id and o.id::text=e.key)
    );
  end if;

  if v_method='participatory_budget' then
    if jsonb_typeof(p_selection->'option_ids') <> 'array' then return false; end if;
    select nullif((rules->>'budget_total'),'')::numeric into v_budget from public.ballots where id=p_ballot_id;
    if v_budget is null or v_budget<0 then return false; end if;
    select coalesce(sum(o.estimated_cost),0) into v_sum
    from public.ballot_options o
    where o.ballot_id=p_ballot_id
      and o.id::text in (select jsonb_array_elements_text(p_selection->'option_ids'));
    return v_sum<=v_budget and not exists(
      select 1 from jsonb_array_elements_text(p_selection->'option_ids') x
      where not exists(select 1 from public.ballot_options o where o.ballot_id=p_ballot_id and o.id::text=x)
    );
  end if;

  return false;
exception when others then
  return false;
end;
$$;
revoke all on function public.validate_ballot_selection(uuid,jsonb) from public,anon;
grant execute on function public.validate_ballot_selection(uuid,jsonb) to authenticated;

-- Sustituye la función de 002: valida selección y evita guardar una relación actor->recibo.
create or replace function public.cast_ballot(p_ballot_id uuid,p_selection jsonb)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.ballots%rowtype;
  e public.ballot_eligibility%rowtype;
  receipt text := encode(digest(gen_random_uuid()::text || clock_timestamp()::text,'sha256'),'hex');
  v_vote_hash text;
begin
  if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found or b.status<>'open' then raise exception 'Votación no disponible'; end if;
  if b.opens_at is not null and now()<b.opens_at then raise exception 'Votación aún no abierta'; end if;
  if b.closes_at is not null and now()>b.closes_at then raise exception 'Votación cerrada'; end if;
  if b.rules_hash is null or b.options_hash is null then raise exception 'La votación no fue congelada correctamente'; end if;

  select * into e from public.ballot_eligibility
  where ballot_id=p_ballot_id and user_id=(select auth.uid()) for update;
  if not found or not e.eligible then raise exception 'Persona no habilitada'; end if;
  if e.voted_at is not null then raise exception 'Ya registró participación en esta votación'; end if;
  if not exists(
    select 1 from public.citizen_profiles p
    where p.id=(select auth.uid()) and p.active and p.verification_level>=b.verification_required
  ) then raise exception 'Nivel de verificación insuficiente'; end if;
  if not public.validate_ballot_selection(p_ballot_id,p_selection) then
    raise exception 'Selección inválida para el método de esta votación';
  end if;

  v_vote_hash := encode(digest(convert_to(p_selection::text || '|' || receipt,'UTF8'),'sha256'),'hex');
  insert into public.ballot_votes(ballot_id,receipt_hash,selection,cast_at)
    values(p_ballot_id,receipt,p_selection,date_trunc('hour',now()));
  update public.ballot_eligibility set voted_at=now()
    where ballot_id=p_ballot_id and user_id=(select auth.uid());

  -- No se inserta actor_id + receipt en audit_events: esa relación revelaría la selección a quien acceda a ambas tablas.
  perform public.append_integrity_event('ballot_cast','ballot',p_ballot_id,v_vote_hash,jsonb_build_object('receipt_hash',receipt));
  return receipt;
end;
$$;
revoke all on function public.cast_ballot(uuid,jsonb) from public,anon;
grant execute on function public.cast_ballot(uuid,jsonb) to authenticated;

-- Endurece operaciones de congelamiento: solo roles autorizados.
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
  if not public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],p.institution_id,p.id) then
    raise exception 'No autorizado para congelar reglas';
  end if;
  if p.rules_locked_at is not null then raise exception 'Las reglas ya fueron congeladas'; end if;
  v_hash := public.hash_jsonb(p.rules);
  select coalesce(max(snapshot_no),0)+1 into v_no from public.process_rule_snapshots where process_id=p_process_id;
  insert into public.process_rule_snapshots(process_id,snapshot_no,rules,rules_hash,created_by)
    values(p_process_id,v_no,p.rules,v_hash,(select auth.uid()));
  update public.participation_processes set rules_locked_at=now() where id=p_process_id;
  return v_hash;
end;
$$;

create or replace function public.freeze_ballot(p_ballot_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.ballots%rowtype;
  p public.participation_processes%rowtype;
  v_options jsonb;
  v_rules_hash text;
  v_options_hash text;
begin
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found then raise exception 'Votación no encontrada'; end if;
  select * into p from public.participation_processes where id=b.process_id;
  if not public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],p.institution_id,p.id) then
    raise exception 'No autorizado para congelar votación';
  end if;
  if b.status<>'draft' then raise exception 'Solo se puede congelar una votación en borrador'; end if;
  select jsonb_agg(jsonb_build_object(
    'id',o.id,'proposal_id',o.proposal_id,'label',o.label,'sort_order',o.sort_order,'estimated_cost',o.estimated_cost
  ) order by o.sort_order,o.id) into v_options
  from public.ballot_options o where o.ballot_id=p_ballot_id;
  if v_options is null then raise exception 'La votación no tiene opciones'; end if;
  v_rules_hash:=public.hash_jsonb(b.rules);
  v_options_hash:=public.hash_jsonb(v_options);
  update public.ballots set rules_hash=v_rules_hash,options_hash=v_options_hash where id=p_ballot_id;
  return jsonb_build_object('rules_hash',v_rules_hash,'options_hash',v_options_hash);
end;
$$;
