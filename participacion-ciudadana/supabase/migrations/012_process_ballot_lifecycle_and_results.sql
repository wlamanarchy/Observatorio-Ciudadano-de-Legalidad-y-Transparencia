-- Ciclo administrativo de procesos y votaciones con resultados agregados auditables.
-- Requiere 001-011.

create table if not exists public.ballot_results(
  ballot_id uuid primary key references public.ballots(id) on delete cascade,
  method text not null,
  result jsonb not null,
  result_hash text not null,
  participant_count bigint not null default 0,
  certification_status text not null default 'tallied' check(certification_status in ('tallied','audited','certified','invalidated')),
  tallied_at timestamptz not null default now(),
  tallied_by uuid references auth.users(id),
  audited_at timestamptz,
  audited_by uuid references auth.users(id),
  certified_at timestamptz,
  certified_by uuid references auth.users(id),
  notes text
);

alter table public.ballot_results enable row level security;
create policy ballot_results_public_read on public.ballot_results for select to anon,authenticated using(true);
grant select(ballot_id,method,result,result_hash,participant_count,certification_status,tallied_at,audited_at,certified_at,notes)
  on public.ballot_results to anon,authenticated;

create index if not exists ballot_results_tallied_by_idx on public.ballot_results(tallied_by);
create index if not exists ballot_results_audited_by_idx on public.ballot_results(audited_by);
create index if not exists ballot_results_certified_by_idx on public.ballot_results(certified_by);

create or replace function public.admin_create_process(
  p_title text,
  p_process_type text,
  p_legal_nature text,
  p_scope_level text,
  p_rules jsonb,
  p_institution_id uuid default null,
  p_region text default null,
  p_department text default null,
  p_municipality text default null
)
returns uuid
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
declare v_id uuid:=extensions.gen_random_uuid();
begin
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','institution_admin'],p_institution_id,null) then raise exception 'No autorizado'; end if;
  if length(trim(coalesce(p_title,'')))<10 then raise exception 'Título demasiado corto'; end if;
  if p_legal_nature not in ('consultivo','priorizacion_participativa','presupuesto_participativo','mecanismo_formal') then raise exception 'Naturaleza jurídica inválida'; end if;
  if p_scope_level not in ('nacional','regional','departamental','distrital','municipal','local','institucional') then raise exception 'Ámbito inválido'; end if;
  insert into public.participation_processes(id,institution_id,title,process_type,legal_nature,scope_level,region,department,municipality,status,rules,created_by)
  values(v_id,p_institution_id,trim(p_title),trim(p_process_type),p_legal_nature,p_scope_level,nullif(trim(coalesce(p_region,'')),''),nullif(trim(coalesce(p_department,'')),''),nullif(trim(coalesce(p_municipality,'')),''),'draft',coalesce(p_rules,'{}'::jsonb),auth.uid());
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'process_created','participation_process',v_id,jsonb_build_object('legal_nature',p_legal_nature,'scope_level',p_scope_level));
  return v_id;
end;
$$;
revoke all on function public.admin_create_process(text,text,text,text,jsonb,uuid,text,text,text) from public,anon;
grant execute on function public.admin_create_process(text,text,text,text,jsonb,uuid,text,text,text) to authenticated;

create or replace function public.admin_set_process_status(p_process_id uuid,p_status text)
returns void
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
declare p public.participation_processes%rowtype;
begin
  select * into p from public.participation_processes where id=p_process_id for update;
  if not found then raise exception 'Proceso no encontrado'; end if;
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','institution_admin','process_facilitator'],p.institution_id,p.id) then raise exception 'No autorizado'; end if;
  if p_status not in ('draft','diagnostic','deliberation','evaluation','prioritization','voting','response','implementation','closed') then raise exception 'Estado inválido'; end if;
  if p.rules_locked_at is not null and p_status='draft' then raise exception 'Un proceso con reglas congeladas no puede volver a borrador'; end if;
  update public.participation_processes set status=p_status,updated_at=now() where id=p_process_id;
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'process_status_changed','participation_process',p_process_id,jsonb_build_object('from',p.status,'to',p_status));
end;
$$;
revoke all on function public.admin_set_process_status(uuid,text) from public,anon;
grant execute on function public.admin_set_process_status(uuid,text) to authenticated;

create or replace function public.admin_publish_consensus_rules(
  p_process_id uuid,
  p_min_participants bigint default null,
  p_min_turnout_pct numeric default null,
  p_min_support_pct numeric default null,
  p_min_territories integer default null,
  p_min_territory_support_pct numeric default null,
  p_additional_rules jsonb default '{}'::jsonb
)
returns text
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare p public.participation_processes%rowtype; v_rules jsonb; v_hash text;
begin
  select * into p from public.participation_processes where id=p_process_id for update;
  if not found then raise exception 'Proceso no encontrado'; end if;
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin'],p.institution_id,p.id) then raise exception 'No autorizado'; end if;
  if p.rules_locked_at is not null then raise exception 'No se pueden cambiar criterios de consenso después de congelar las reglas'; end if;
  v_rules:=jsonb_build_object('min_participants',p_min_participants,'min_turnout_pct',p_min_turnout_pct,'min_support_pct',p_min_support_pct,'min_territories',p_min_territories,'min_territory_support_pct',p_min_territory_support_pct,'additional_rules',coalesce(p_additional_rules,'{}'::jsonb));
  v_hash:=public.hash_jsonb(v_rules);
  insert into public.consensus_rules(process_id,min_participants,min_turnout_pct,min_support_pct,min_territories,min_territory_support_pct,additional_rules,published_at,rules_hash)
  values(p_process_id,p_min_participants,p_min_turnout_pct,p_min_support_pct,p_min_territories,p_min_territory_support_pct,coalesce(p_additional_rules,'{}'::jsonb),now(),v_hash)
  on conflict(process_id) do update set min_participants=excluded.min_participants,min_turnout_pct=excluded.min_turnout_pct,min_support_pct=excluded.min_support_pct,min_territories=excluded.min_territories,min_territory_support_pct=excluded.min_territory_support_pct,additional_rules=excluded.additional_rules,published_at=now(),rules_hash=excluded.rules_hash,updated_at=now();
  return v_hash;
end;
$$;
revoke all on function public.admin_publish_consensus_rules(uuid,bigint,numeric,numeric,integer,numeric,jsonb) from public,anon;
grant execute on function public.admin_publish_consensus_rules(uuid,bigint,numeric,numeric,integer,numeric,jsonb) to authenticated;

create or replace function public.admin_create_ballot(
  p_process_id uuid,p_title text,p_method text,p_rules jsonb,p_verification_required smallint default 1,p_integrity_level text default 'pilot'
)
returns uuid
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare p public.participation_processes%rowtype; v_id uuid:=extensions.gen_random_uuid();
begin
  select * into p from public.participation_processes where id=p_process_id;
  if not found then raise exception 'Proceso no encontrado'; end if;
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','institution_admin','process_facilitator'],p.institution_id,p.id) then raise exception 'No autorizado'; end if;
  if p_method not in ('approval','ranked','yes_no','points100','participatory_budget') then raise exception 'Método inválido'; end if;
  if p_verification_required<1 or p_verification_required>4 then raise exception 'Nivel de verificación inválido'; end if;
  if p_integrity_level not in ('pilot','enhanced','independent_audit','formal_mechanism') then raise exception 'Nivel de integridad inválido'; end if;
  if p_method='ranked' and coalesce(p_rules->>'ranked_tally','') not in ('borda') then raise exception 'Para ranked debe congelarse ranked_tally=borda en esta versión del piloto'; end if;
  insert into public.ballots(id,process_id,title,method,rules,verification_required,status,integrity_level,software_commit)
  values(v_id,p_process_id,trim(p_title),p_method,coalesce(p_rules,'{}'::jsonb),p_verification_required,'draft',p_integrity_level,null)
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.admin_create_ballot(uuid,text,text,jsonb,smallint,text) from public,anon;
grant execute on function public.admin_create_ballot(uuid,text,text,jsonb,smallint,text) to authenticated;

create or replace function public.admin_add_ballot_option(p_ballot_id uuid,p_label text,p_proposal_id uuid default null,p_estimated_cost numeric default null)
returns uuid
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare b public.ballots%rowtype; p public.participation_processes%rowtype; v_id uuid:=extensions.gen_random_uuid(); v_order int;
begin
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found or b.status<>'draft' then raise exception 'Votación no disponible para edición'; end if;
  select * into p from public.participation_processes where id=b.process_id;
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','institution_admin','process_facilitator'],p.institution_id,p.id) then raise exception 'No autorizado'; end if;
  if p_proposal_id is not null and not exists(select 1 from public.proposals where id=p_proposal_id and process_id=b.process_id) then raise exception 'La propuesta no pertenece al proceso'; end if;
  select coalesce(max(sort_order),0)+1 into v_order from public.ballot_options where ballot_id=p_ballot_id;
  insert into public.ballot_options(id,ballot_id,proposal_id,label,sort_order,estimated_cost) values(v_id,p_ballot_id,p_proposal_id,trim(p_label),v_order,p_estimated_cost);
  return v_id;
end;
$$;
revoke all on function public.admin_add_ballot_option(uuid,text,uuid,numeric) from public,anon;
grant execute on function public.admin_add_ballot_option(uuid,text,uuid,numeric) to authenticated;

create or replace function public.admin_open_ballot(p_ballot_id uuid,p_opens_at timestamptz,p_closes_at timestamptz,p_software_commit text default null)
returns jsonb
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare b public.ballots%rowtype; p public.participation_processes%rowtype; v_hashes jsonb;
begin
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found or b.status<>'draft' then raise exception 'Votación no disponible para apertura'; end if;
  select * into p from public.participation_processes where id=b.process_id for update;
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','institution_admin','process_facilitator'],p.institution_id,p.id) then raise exception 'No autorizado'; end if;
  if p_closes_at is null or p_opens_at is null or p_closes_at<=p_opens_at then raise exception 'Ventana temporal inválida'; end if;
  if not exists(select 1 from public.consensus_rules c where c.process_id=p.id and c.published_at is not null) then raise exception 'Publique criterios de consenso/resultado antes de abrir'; end if;
  if p.rules_locked_at is null then perform public.lock_process_rules(p.id); end if;
  v_hashes:=public.freeze_ballot(p_ballot_id);
  update public.ballots set opens_at=p_opens_at,closes_at=p_closes_at,software_commit=p_software_commit,status='open' where id=p_ballot_id;
  update public.participation_processes set status='voting',updated_at=now() where id=p.id;
  perform public.append_integrity_event('ballot_opened','ballot',p_ballot_id,public.hash_jsonb(v_hashes),jsonb_build_object('opens_at',p_opens_at,'closes_at',p_closes_at,'software_commit',p_software_commit));
  return v_hashes;
end;
$$;
revoke all on function public.admin_open_ballot(uuid,timestamptz,timestamptz,text) from public,anon;
grant execute on function public.admin_open_ballot(uuid,timestamptz,timestamptz,text) to authenticated;

create or replace function public.admin_close_and_tally_ballot(p_ballot_id uuid,p_notes text default null)
returns jsonb
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare b public.ballots%rowtype; p public.participation_processes%rowtype; v_result jsonb; v_hash text; v_participants bigint;
begin
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found or b.status<>'open' then raise exception 'Votación no está abierta'; end if;
  select * into p from public.participation_processes where id=b.process_id;
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','independent_auditor'],p.institution_id,p.id) then raise exception 'No autorizado'; end if;
  if b.closes_at is not null and now()<b.closes_at and not private.is_platform_admin(auth.uid()) then raise exception 'La votación aún no ha cerrado'; end if;
  select count(*) into v_participants from public.ballot_eligibility where ballot_id=p_ballot_id and voted_at is not null;

  if b.method='yes_no' then
    select jsonb_build_object(
      'yes',count(*) filter(where selection->>'choice'='yes'),
      'no',count(*) filter(where selection->>'choice'='no'),
      'abstain',count(*) filter(where selection->>'choice'='abstain')
    ) into v_result from public.ballot_votes where ballot_id=p_ballot_id;
  elsif b.method in ('approval','participatory_budget') then
    select coalesce(jsonb_agg(jsonb_build_object('option_id',o.id,'label',o.label,'votes',coalesce(x.n,0),'estimated_cost',o.estimated_cost) order by o.sort_order,o.id),'[]'::jsonb)
    into v_result
    from public.ballot_options o
    left join lateral (
      select count(*) n from public.ballot_votes v
      where v.ballot_id=p_ballot_id and exists(select 1 from jsonb_array_elements_text(v.selection->'option_ids') q where q=o.id::text)
    ) x on true
    where o.ballot_id=p_ballot_id;
  elsif b.method='points100' then
    select coalesce(jsonb_agg(jsonb_build_object('option_id',o.id,'label',o.label,'points',coalesce(x.points,0)) order by o.sort_order,o.id),'[]'::jsonb)
    into v_result
    from public.ballot_options o
    left join lateral (
      select coalesce(sum((v.selection->'points'->>o.id::text)::numeric),0) points
      from public.ballot_votes v where v.ballot_id=p_ballot_id
    ) x on true
    where o.ballot_id=p_ballot_id;
  elsif b.method='ranked' and b.rules->>'ranked_tally'='borda' then
    select coalesce(jsonb_agg(jsonb_build_object('option_id',o.id,'label',o.label,'borda_points',coalesce(x.points,0)) order by coalesce(x.points,0) desc,o.sort_order,o.id),'[]'::jsonb)
    into v_result
    from public.ballot_options o
    left join lateral (
      select coalesce(sum(greatest(0,jsonb_array_length(v.selection->'ranking')-q.ord+1)),0) points
      from public.ballot_votes v
      cross join lateral jsonb_array_elements_text(v.selection->'ranking') with ordinality q(val,ord)
      where v.ballot_id=p_ballot_id and q.val=o.id::text
    ) x on true
    where o.ballot_id=p_ballot_id;
  else
    raise exception 'Método de escrutinio no implementado o no congelado';
  end if;

  v_result:=jsonb_build_object('method',b.method,'totals',v_result,'participant_count',v_participants,'closed_at',now());
  v_hash:=public.hash_jsonb(v_result);
  insert into public.ballot_results(ballot_id,method,result,result_hash,participant_count,certification_status,tallied_at,tallied_by,notes)
  values(p_ballot_id,b.method,v_result,v_hash,v_participants,'tallied',now(),auth.uid(),p_notes)
  on conflict(ballot_id) do update set method=excluded.method,result=excluded.result,result_hash=excluded.result_hash,participant_count=excluded.participant_count,certification_status='tallied',tallied_at=now(),tallied_by=auth.uid(),notes=excluded.notes;
  update public.ballots set status='closed',result_hash=v_hash where id=p_ballot_id;
  perform public.append_integrity_event('ballot_tallied','ballot',p_ballot_id,v_hash,jsonb_build_object('participant_count',v_participants));
  return v_result;
end;
$$;
revoke all on function public.admin_close_and_tally_ballot(uuid,text) from public,anon;
grant execute on function public.admin_close_and_tally_ballot(uuid,text) to authenticated;

create or replace function public.admin_certify_ballot(p_ballot_id uuid,p_notes text default null)
returns void
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
declare r public.ballot_results%rowtype;
begin
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['independent_auditor'],null,null) then raise exception 'No autorizado'; end if;
  select * into r from public.ballot_results where ballot_id=p_ballot_id for update;
  if not found then raise exception 'Resultado no encontrado'; end if;
  update public.ballot_results set certification_status='certified',certified_at=now(),certified_by=auth.uid(),notes=coalesce(p_notes,notes) where ballot_id=p_ballot_id;
  update public.ballots set status='certified' where id=p_ballot_id;
  perform public.append_integrity_event('ballot_certified','ballot',p_ballot_id,r.result_hash,jsonb_build_object('certified_at',now()));
end;
$$;
revoke all on function public.admin_certify_ballot(uuid,text) from public,anon;
grant execute on function public.admin_certify_ballot(uuid,text) to authenticated;

create or replace view public.public_ballot_results
with (security_invoker=true)
as
select ballot_id,method,result,result_hash,participant_count,certification_status,tallied_at,audited_at,certified_at,notes
from public.ballot_results;
grant select on public.public_ballot_results to anon,authenticated;
