-- Runtime del piloto: onboarding, propuestas, aportes y solicitudes de elegibilidad.
-- Requiere migraciones 001-005.

create or replace function public.handle_new_citizen()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  insert into public.citizen_profiles(id,display_name,verification_level)
  values(
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(coalesce(new.email,''),'@',1)),
    1
  )
  on conflict(id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_participation on auth.users;
create trigger on_auth_user_created_participation
after insert on auth.users
for each row execute procedure public.handle_new_citizen();

-- Usuarios ya existentes obtienen perfil sin elevar privilegios.
insert into public.citizen_profiles(id,display_name,verification_level)
select u.id,coalesce(u.raw_user_meta_data->>'name',split_part(coalesce(u.email,''),'@',1)),1
from auth.users u
left join public.citizen_profiles p on p.id=u.id
where p.id is null
on conflict(id) do nothing;

create table if not exists public.ballot_eligibility_requests(
  id uuid primary key default gen_random_uuid(),
  ballot_id uuid not null references public.ballots(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rationale text,
  status text not null default 'pending' check(status in ('pending','approved','rejected','withdrawn')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users(id),
  unique(ballot_id,user_id)
);

alter table public.ballot_eligibility_requests enable row level security;

create policy eligibility_requests_self_read on public.ballot_eligibility_requests
for select to authenticated
using(user_id=(select auth.uid()) or public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']));

create policy eligibility_requests_self_insert on public.ballot_eligibility_requests
for insert to authenticated
with check(user_id=(select auth.uid()));

create policy eligibility_requests_admin_update on public.ballot_eligibility_requests
for update to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']))
with check(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']));

create or replace function public.submit_citizen_proposal(
  p_process_id uuid,
  p_title text,
  p_summary text,
  p_problem text,
  p_expected_outcome text default null,
  p_theme text default null,
  p_scope_level text default 'nacional',
  p_region text default null,
  p_department text default null,
  p_municipality text default null,
  p_evidence jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid:=gen_random_uuid();
  v_process public.participation_processes%rowtype;
begin
  if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
  if length(trim(coalesce(p_title,'')))<8 then raise exception 'Título demasiado corto'; end if;
  if length(trim(coalesce(p_summary,'')))<40 then raise exception 'Resumen demasiado corto'; end if;
  if length(trim(coalesce(p_problem,'')))<40 then raise exception 'Diagnóstico demasiado corto'; end if;

  select * into v_process from public.participation_processes where id=p_process_id;
  if not found then raise exception 'Proceso de participación no encontrado'; end if;
  if v_process.status not in ('diagnostic','deliberation','evaluation','prioritization') then
    raise exception 'El proceso no recibe propuestas en esta etapa';
  end if;

  insert into public.proposals(
    id,process_id,title,summary,problem,expected_outcome,theme,scope_level,region,department,municipality,status,created_by
  ) values(
    v_id,p_process_id,trim(p_title),trim(p_summary),trim(p_problem),nullif(trim(coalesce(p_expected_outcome,'')),''),
    nullif(trim(coalesce(p_theme,'')),''),coalesce(nullif(trim(coalesce(p_scope_level,'')),''),'nacional'),
    nullif(trim(coalesce(p_region,'')),''),nullif(trim(coalesce(p_department,'')),''),nullif(trim(coalesce(p_municipality,'')),''),
    'published',auth.uid()
  );

  insert into public.proposal_versions(proposal_id,version_no,content,change_note,created_by)
  values(v_id,1,jsonb_build_object(
    'title',trim(p_title),'summary',trim(p_summary),'problem',trim(p_problem),'expected_outcome',p_expected_outcome,
    'theme',p_theme,'scope_level',p_scope_level,'region',p_region,'department',p_department,'municipality',p_municipality,
    'evidence',coalesce(p_evidence,'[]'::jsonb)
  ),'Versión inicial ciudadana',auth.uid());

  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'proposal_submitted','proposal',v_id,jsonb_build_object('process_id',p_process_id));

  return v_id;
end;
$$;
revoke all on function public.submit_citizen_proposal(uuid,text,text,text,text,text,text,text,text,text,jsonb) from public,anon;
grant execute on function public.submit_citizen_proposal(uuid,text,text,text,text,text,text,text,text,text,jsonb) to authenticated;

create or replace function public.submit_contribution(
  p_proposal_id uuid,
  p_type text,
  p_body text,
  p_source_url text default null
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid:=gen_random_uuid();
  v_status text;
begin
  if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
  if p_type not in ('supporting_argument','opposing_argument','alternative','question','amendment','evidence') then
    raise exception 'Tipo de aporte inválido';
  end if;
  if length(trim(coalesce(p_body,'')))<20 then raise exception 'Aporte demasiado corto'; end if;
  select status into v_status from public.proposals where id=p_proposal_id;
  if v_status is null or v_status in ('withdrawn','implemented') then raise exception 'Propuesta no disponible para aportes'; end if;

  insert into public.contributions(id,proposal_id,contribution_type,body,source_url,status,created_by)
  values(v_id,p_proposal_id,p_type,trim(p_body),nullif(trim(coalesce(p_source_url,'')),''),'visible',auth.uid());

  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'contribution_submitted','contribution',v_id,jsonb_build_object('proposal_id',p_proposal_id,'type',p_type));
  return v_id;
end;
$$;
revoke all on function public.submit_contribution(uuid,text,text,text) from public,anon;
grant execute on function public.submit_contribution(uuid,text,text,text) to authenticated;

create or replace function public.request_ballot_eligibility(p_ballot_id uuid,p_rationale text default null)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
  if not exists(select 1 from public.ballots b where b.id=p_ballot_id and b.status in ('draft','open')) then
    raise exception 'Votación no disponible';
  end if;
  insert into public.ballot_eligibility_requests(ballot_id,user_id,rationale)
  values(p_ballot_id,auth.uid(),nullif(trim(coalesce(p_rationale,'')),''))
  on conflict(ballot_id,user_id) do update set
    rationale=excluded.rationale,
    status=case when public.ballot_eligibility_requests.status='withdrawn' then 'pending' else public.ballot_eligibility_requests.status end
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.request_ballot_eligibility(uuid,text) from public,anon;
grant execute on function public.request_ballot_eligibility(uuid,text) to authenticated;

-- Vista pública segura para la interfaz: no expone created_by.
create or replace view public.public_proposal_feed
with (security_invoker=true)
as
select
  p.id,p.process_id,p.diagnostic_id,p.title,p.summary,p.problem,p.expected_outcome,p.theme,p.scope_level,
  p.region,p.department,p.municipality,p.status,p.created_at,p.updated_at,
  coalesce(count(c.id) filter(where c.status='visible'),0)::bigint as contribution_count
from public.proposals p
left join public.contributions c on c.proposal_id=p.id
where p.status<>'draft'
group by p.id;

grant select on public.public_proposal_feed to anon,authenticated;

create or replace view public.public_process_directory
with (security_invoker=true)
as
select id,institution_id,title,process_type,legal_nature,scope_level,region,department,municipality,status,
       rules_locked_at,opens_at,closes_at,created_at,updated_at
from public.participation_processes
where status<>'draft';

grant select on public.public_process_directory to anon,authenticated;
