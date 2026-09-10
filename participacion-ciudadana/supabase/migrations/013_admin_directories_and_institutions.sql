-- Directorios administrativos seguros y gestión básica de instituciones.
-- Requiere 001-012.

create or replace function public.my_governance_roles()
returns table(role text,institution_id uuid,process_id uuid,expires_at timestamptz)
language sql
stable
security definer
set search_path=public,pg_temp
as $$
  select r.role,r.institution_id,r.process_id,r.expires_at
  from public.governance_roles r
  where r.user_id=auth.uid() and r.active and (r.expires_at is null or r.expires_at>now())
  order by r.role;
$$;
revoke all on function public.my_governance_roles() from public,anon;
grant execute on function public.my_governance_roles() to authenticated;

create or replace function public.admin_list_processes()
returns setof public.participation_processes
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
begin
  if not private.is_platform_admin(auth.uid())
     and not public.has_governance_role(array['methodology_admin','institution_admin','process_facilitator'],null,null)
  then raise exception 'No autorizado'; end if;
  return query select * from public.participation_processes order by created_at desc;
end;
$$;
revoke all on function public.admin_list_processes() from public,anon;
grant execute on function public.admin_list_processes() to authenticated;

create or replace function public.admin_list_ballots()
returns table(
  id uuid,process_id uuid,title text,method text,rules jsonb,verification_required smallint,status text,
  opens_at timestamptz,closes_at timestamptz,rules_hash text,options_hash text,result_hash text,
  software_commit text,integrity_level text,created_at timestamptz
)
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
begin
  if not private.is_platform_admin(auth.uid())
     and not public.has_governance_role(array['methodology_admin','institution_admin','process_facilitator','independent_auditor'],null,null)
  then raise exception 'No autorizado'; end if;
  return query
  select b.id,b.process_id,b.title,b.method,b.rules,b.verification_required,b.status,b.opens_at,b.closes_at,
         b.rules_hash,b.options_hash,b.result_hash,b.software_commit,b.integrity_level,b.created_at
  from public.ballots b order by b.created_at desc;
end;
$$;
revoke all on function public.admin_list_ballots() from public,anon;
grant execute on function public.admin_list_ballots() to authenticated;

create or replace function public.admin_list_governance_roles()
returns table(
  role_id uuid,user_id uuid,email text,display_name text,role text,institution_id uuid,process_id uuid,
  active boolean,expires_at timestamptz,created_at timestamptz
)
language plpgsql
security definer
set search_path=public,private,auth,pg_temp
as $$
begin
  if not private.is_platform_admin(auth.uid()) then raise exception 'No autorizado'; end if;
  return query
  select r.id,r.user_id,u.email,p.display_name,r.role,r.institution_id,r.process_id,r.active,r.expires_at,r.created_at
  from public.governance_roles r
  join auth.users u on u.id=r.user_id
  left join public.citizen_profiles p on p.id=r.user_id
  order by r.active desc,r.created_at desc;
end;
$$;
revoke all on function public.admin_list_governance_roles() from public,anon;
grant execute on function public.admin_list_governance_roles() to authenticated;

create or replace function public.admin_create_institution(
  p_name text,p_institution_type text,p_territorial_level text default null,p_region text default null,
  p_department text default null,p_municipality text default null,p_official_url text default null
)
returns uuid
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare v_id uuid:=extensions.gen_random_uuid();
begin
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin'],null,null) then raise exception 'No autorizado'; end if;
  if length(trim(coalesce(p_name,'')))<3 then raise exception 'Nombre requerido'; end if;
  insert into public.institutions(id,name,institution_type,territorial_level,region,department,municipality,official_url,active)
  values(v_id,trim(p_name),trim(p_institution_type),nullif(trim(coalesce(p_territorial_level,'')),''),nullif(trim(coalesce(p_region,'')),''),nullif(trim(coalesce(p_department,'')),''),nullif(trim(coalesce(p_municipality,'')),''),nullif(trim(coalesce(p_official_url,'')),''),true);
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'institution_created','institution',v_id,jsonb_build_object('name',trim(p_name),'type',trim(p_institution_type)));
  return v_id;
end;
$$;
revoke all on function public.admin_create_institution(text,text,text,text,text,text,text) from public,anon;
grant execute on function public.admin_create_institution(text,text,text,text,text,text,text) to authenticated;

create or replace function public.admin_update_process_rules(p_process_id uuid,p_rules jsonb)
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
  if p.rules_locked_at is not null then raise exception 'Las reglas están congeladas'; end if;
  update public.participation_processes set rules=coalesce(p_rules,'{}'::jsonb),updated_at=now() where id=p_process_id;
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'process_rules_updated','participation_process',p_process_id,jsonb_build_object('rules_hash',public.hash_jsonb(coalesce(p_rules,'{}'::jsonb))));
end;
$$;
revoke all on function public.admin_update_process_rules(uuid,jsonb) from public,anon;
grant execute on function public.admin_update_process_rules(uuid,jsonb) to authenticated;

create or replace function public.list_public_ballot_results()
returns table(ballot_id uuid,method text,result jsonb,result_hash text,participant_count bigint,certification_status text,tallied_at timestamptz,audited_at timestamptz,certified_at timestamptz,notes text)
language sql
stable
security invoker
set search_path=public,pg_temp
as $$
  select r.ballot_id,r.method,r.result,r.result_hash,r.participant_count,r.certification_status,r.tallied_at,r.audited_at,r.certified_at,r.notes
  from public.ballot_results r
  order by r.tallied_at desc;
$$;
revoke all on function public.list_public_ballot_results() from public;
grant execute on function public.list_public_ballot_results() to anon,authenticated;
