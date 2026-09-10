-- Bootstrap seguro y API administrativa del piloto.
-- Requiere 001-010. No contiene secretos: los códigos bootstrap se generan fuera de la migración.

create schema if not exists private;
revoke all on schema private from public,anon,authenticated;
grant usage on schema private to postgres,service_role;

create table if not exists private.bootstrap_tokens(
  id uuid primary key default extensions.gen_random_uuid(),
  purpose text not null check(purpose in ('platform_admin_bootstrap')),
  token_hash text not null unique,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  consumed_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
revoke all on private.bootstrap_tokens from public,anon,authenticated;

create or replace function private.is_platform_admin(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path=public,private,pg_temp
as $$
  select exists(
    select 1 from public.governance_roles r
    where r.user_id=p_user and r.role='platform_admin' and r.active
      and (r.expires_at is null or r.expires_at>now())
  );
$$;
revoke all on function private.is_platform_admin(uuid) from public,anon,authenticated;

create or replace function public.bootstrap_platform_admin(p_code text)
returns boolean
language plpgsql
security definer
set search_path=public,private,extensions,pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_token private.bootstrap_tokens%rowtype;
begin
  if v_uid is null then raise exception 'Autenticación requerida'; end if;
  if exists(select 1 from public.governance_roles where role='platform_admin' and active) then
    raise exception 'El bootstrap inicial ya fue cerrado';
  end if;
  if length(coalesce(p_code,''))<24 then raise exception 'Código inválido'; end if;

  select * into v_token
  from private.bootstrap_tokens
  where purpose='platform_admin_bootstrap'
    and token_hash=encode(extensions.digest(convert_to(p_code,'UTF8'),'sha256'),'hex')
    and consumed_at is null
    and expires_at>now()
  order by created_at desc
  limit 1
  for update;

  if not found then raise exception 'Código inválido o vencido'; end if;

  insert into public.governance_roles(user_id,role,active,assigned_by)
  values(v_uid,'platform_admin',true,v_uid);

  update private.bootstrap_tokens
    set consumed_at=now(),consumed_by=v_uid
    where id=v_token.id;

  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(v_uid,'platform_admin_bootstrapped','governance_role',null,jsonb_build_object('method','one_time_bootstrap'));

  return true;
end;
$$;
revoke all on function public.bootstrap_platform_admin(text) from public,anon;
grant execute on function public.bootstrap_platform_admin(text) to authenticated;

create or replace function public.my_governance_roles()
returns table(role text,institution_id uuid,process_id uuid,expires_at timestamptz)
language sql
stable
security invoker
set search_path=public,pg_temp
as $$
  select r.role,r.institution_id,r.process_id,r.expires_at
  from public.governance_roles r
  where r.user_id=auth.uid() and r.active and (r.expires_at is null or r.expires_at>now())
  order by r.role;
$$;
revoke all on function public.my_governance_roles() from public,anon;
grant execute on function public.my_governance_roles() to authenticated;

create or replace function public.admin_user_directory()
returns table(user_id uuid,email text,display_name text,verification_level smallint,active boolean,created_at timestamptz)
language plpgsql
security definer
set search_path=public,private,auth,pg_temp
as $$
begin
  if not private.is_platform_admin(auth.uid()) then raise exception 'No autorizado'; end if;
  return query
  select u.id,u.email,p.display_name,p.verification_level,p.active,u.created_at
  from auth.users u
  left join public.citizen_profiles p on p.id=u.id
  order by u.created_at desc;
end;
$$;
revoke all on function public.admin_user_directory() from public,anon;
grant execute on function public.admin_user_directory() to authenticated;

create or replace function public.admin_assign_governance_role(
  p_user_id uuid,
  p_role text,
  p_institution_id uuid default null,
  p_process_id uuid default null,
  p_expires_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
declare v_id uuid;
begin
  if not private.is_platform_admin(auth.uid()) then raise exception 'No autorizado'; end if;
  if p_role not in ('platform_admin','methodology_admin','institution_admin','process_facilitator','moderator','technical_evaluator','independent_auditor','data_steward') then
    raise exception 'Rol inválido';
  end if;
  if p_institution_id is not null and p_process_id is not null then raise exception 'Asigne ámbito institucional o de proceso, no ambos'; end if;
  if not exists(select 1 from auth.users where id=p_user_id) then raise exception 'Usuario no encontrado'; end if;

  insert into public.governance_roles(user_id,role,institution_id,process_id,active,expires_at,assigned_by)
  values(p_user_id,p_role,p_institution_id,p_process_id,true,p_expires_at,auth.uid())
  returning id into v_id;

  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'governance_role_assigned','governance_role',v_id,
    jsonb_build_object('role',p_role,'user_id',p_user_id,'institution_id',p_institution_id,'process_id',p_process_id,'expires_at',p_expires_at));
  return v_id;
end;
$$;
revoke all on function public.admin_assign_governance_role(uuid,text,uuid,uuid,timestamptz) from public,anon;
grant execute on function public.admin_assign_governance_role(uuid,text,uuid,uuid,timestamptz) to authenticated;

create or replace function public.admin_revoke_governance_role(p_role_id uuid)
returns void
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
declare v_role public.governance_roles%rowtype;
begin
  if not private.is_platform_admin(auth.uid()) then raise exception 'No autorizado'; end if;
  select * into v_role from public.governance_roles where id=p_role_id for update;
  if not found then raise exception 'Rol no encontrado'; end if;
  if v_role.role='platform_admin' and v_role.user_id=auth.uid()
     and (select count(*) from public.governance_roles where role='platform_admin' and active and (expires_at is null or expires_at>now()))<=1 then
    raise exception 'No se puede revocar el último administrador de plataforma';
  end if;
  update public.governance_roles set active=false where id=p_role_id;
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'governance_role_revoked','governance_role',p_role_id,jsonb_build_object('role',v_role.role,'user_id',v_role.user_id));
end;
$$;
revoke all on function public.admin_revoke_governance_role(uuid) from public,anon;
grant execute on function public.admin_revoke_governance_role(uuid) to authenticated;

create or replace function public.admin_set_verification_level(p_user_id uuid,p_level smallint)
returns void
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
begin
  if not private.is_platform_admin(auth.uid()) then raise exception 'No autorizado'; end if;
  if p_level<0 or p_level>4 then raise exception 'Nivel inválido'; end if;
  update public.citizen_profiles set verification_level=p_level,updated_at=now() where id=p_user_id;
  if not found then raise exception 'Perfil no encontrado'; end if;
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'verification_level_changed','citizen_profile',p_user_id,jsonb_build_object('level',p_level));
end;
$$;
revoke all on function public.admin_set_verification_level(uuid,smallint) from public,anon;
grant execute on function public.admin_set_verification_level(uuid,smallint) to authenticated;

create or replace function public.admin_pending_eligibility_requests()
returns table(
  request_id uuid,ballot_id uuid,ballot_title text,user_id uuid,display_name text,
  verification_level smallint,rationale text,status text,created_at timestamptz
)
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
begin
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','independent_auditor'],null,null) then
    raise exception 'No autorizado';
  end if;
  return query
  select r.id,r.ballot_id,b.title,r.user_id,p.display_name,p.verification_level,r.rationale,r.status,r.created_at
  from public.ballot_eligibility_requests r
  join public.ballots b on b.id=r.ballot_id
  left join public.citizen_profiles p on p.id=r.user_id
  where r.status='pending'
  order by r.created_at asc;
end;
$$;
revoke all on function public.admin_pending_eligibility_requests() from public,anon;
grant execute on function public.admin_pending_eligibility_requests() to authenticated;

create or replace function public.admin_decide_eligibility(p_request_id uuid,p_approve boolean,p_reason text default null)
returns void
language plpgsql
security definer
set search_path=public,private,pg_temp
as $$
declare r public.ballot_eligibility_requests%rowtype;
begin
  if not private.is_platform_admin(auth.uid()) and not public.has_governance_role(array['methodology_admin','independent_auditor'],null,null) then
    raise exception 'No autorizado';
  end if;
  select * into r from public.ballot_eligibility_requests where id=p_request_id for update;
  if not found then raise exception 'Solicitud no encontrada'; end if;
  if r.status<>'pending' then raise exception 'Solicitud ya decidida'; end if;

  update public.ballot_eligibility_requests
  set status=case when p_approve then 'approved' else 'rejected' end,
      decided_at=now(),decided_by=auth.uid(),
      rationale=case when p_reason is null then rationale else concat_ws(E'\n',rationale,'Decisión: '||p_reason) end
  where id=p_request_id;

  if p_approve then
    insert into public.ballot_eligibility(ballot_id,user_id,eligible)
    values(r.ballot_id,r.user_id,true)
    on conflict(ballot_id,user_id) do update set eligible=true;
  end if;

  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'eligibility_decided','eligibility_request',p_request_id,
    jsonb_build_object('approved',p_approve,'ballot_id',r.ballot_id,'user_id',r.user_id,'reason',p_reason));
end;
$$;
revoke all on function public.admin_decide_eligibility(uuid,boolean,text) from public,anon;
grant execute on function public.admin_decide_eligibility(uuid,boolean,text) to authenticated;
