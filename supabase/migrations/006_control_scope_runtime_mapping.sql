-- Mapea el formulario detallado del Observatorio a columnas estructuradas,
-- manteniendo un nivel amplio para enrutamiento de curaduría.

create or replace function public.submit_report(p_report jsonb, p_contact text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := gen_random_uuid();
  v_level text := coalesce(p_report->>'nivel','nacional');
  v_scope text := nullif(p_report->>'ambitoTipo','');
  v_entity_type text;
  v_route text;
begin
  if v_level not in ('nacional','departamental','distrital','municipal','regional') then raise exception 'Nivel de vigilancia inválido'; end if;
  if v_scope is not null and not exists(select 1 from public.control_scope_type_catalog where code=v_scope and active=true) then raise exception 'Ámbito de control inválido'; end if;
  select code into v_entity_type from public.control_entity_type_catalog where active=true and (code=p_report->>'entidadTipo' or lower(name)=lower(p_report->>'entidadTipo')) limit 1;
  select code into v_route from public.control_route_catalog where active=true and (code=p_report->>'rutaControl' or lower(name)=lower(p_report->>'rutaControl')) limit 1;
  if length(trim(coalesce(p_report->>'entidad',''))) < 2 then raise exception 'Entidad requerida'; end if;
  if length(trim(coalesce(p_report->>'actoId',''))) < 2 then raise exception 'Identificación del acto requerida'; end if;
  if length(trim(coalesce(p_report->>'hecho',''))) < 40 then raise exception 'Relato demasiado corto'; end if;

  insert into public.reports(
    id,level,region,department,municipality,territory,scope_type_code,scope_name,entity_type_code,subject_matter,impact_level,control_route_code,
    entity_name,act_type,act_id,act_date,class_hint,payload
  ) values (
    v_id,v_level,nullif(p_report->>'region',''),nullif(p_report->>'departamento',''),nullif(p_report->>'municipio',''),nullif(p_report->>'territorio',''),
    v_scope,nullif(p_report->>'ambitoNombre',''),v_entity_type,nullif(p_report->>'materia',''),nullif(p_report->>'impacto',''),v_route,
    p_report->>'entidad',coalesce(p_report->>'actoTipo','Actuación'),p_report->>'actoId',nullif(p_report->>'fecha','')::date,nullif(p_report->>'clase',''),p_report-'contacto'
  );
  if p_contact is not null and length(trim(p_contact))>0 then insert into public.reporter_private(report_id,contact) values(v_id,p_contact); end if;
  return v_id;
end;
$$;
revoke all on function public.submit_report(jsonb,text) from public;
grant execute on function public.submit_report(jsonb,text) to anon,authenticated;

create or replace function public.resolve_report(p_report_id uuid,p_finding jsonb,p_outcome text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.reports%rowtype;
  v_finding_id uuid;
  v_entity_type text;
  v_route text;
begin
  select * into r from public.reports where id=p_report_id for update;
  if not found then raise exception 'Reporte no encontrado'; end if;
  if not public.can_curate_scope(r.level,r.region,r.department,r.municipality) then raise exception 'Sin competencia de curaduría para este territorio'; end if;
  if p_outcome='promoted' then
    if p_finding is null then raise exception 'Ficha requerida'; end if;
    select code into v_entity_type from public.control_entity_type_catalog where active=true and (code=p_finding->>'entidadTipo' or lower(name)=lower(p_finding->>'entidadTipo')) limit 1;
    select code into v_route from public.control_route_catalog where active=true and (code=p_finding->>'rutaControl' or lower(name)=lower(p_finding->>'rutaControl')) limit 1;
    v_finding_id:=gen_random_uuid();
    insert into public.findings(
      id,level,region,department,municipality,territory,scope_type_code,scope_name,entity_type_code,subject_matter,impact_level,control_route_code,
      entity_name,act_type,act_id,act_date,finding_class,verification_status,replica_status,published,payload,created_by,updated_by
    ) values (
      v_finding_id,coalesce(p_finding->>'nivel',r.level),coalesce(nullif(p_finding->>'region',''),r.region),coalesce(nullif(p_finding->>'departamento',''),r.department),
      coalesce(nullif(p_finding->>'municipio',''),r.municipality),coalesce(nullif(p_finding->>'territorio',''),r.territory),
      coalesce(nullif(p_finding->>'ambitoTipo',''),r.scope_type_code),coalesce(nullif(p_finding->>'ambitoNombre',''),r.scope_name),coalesce(v_entity_type,r.entity_type_code),
      coalesce(nullif(p_finding->>'materia',''),r.subject_matter),coalesce(nullif(p_finding->>'impacto',''),r.impact_level),coalesce(v_route,r.control_route_code),
      coalesce(p_finding->>'entidad',r.entity_name),coalesce(p_finding->>'actoTipo',r.act_type),coalesce(p_finding->>'actoId',r.act_id),coalesce(nullif(p_finding->>'fecha','')::date,r.act_date),
      coalesce(p_finding->>'clase',r.class_hint,'integridad'),coalesce(p_finding->>'verificacion','verificacion'),coalesce(p_finding->>'replica','no_notificado'),false,
      p_finding||jsonb_build_object('id',v_finding_id),auth.uid(),auth.uid()
    );
    update public.reports set status='promoted',resolved_at=now(),resolved_by=auth.uid() where id=p_report_id;
  elsif p_outcome='discarded' then
    update public.reports set status='discarded',resolved_at=now(),resolved_by=auth.uid() where id=p_report_id;
  else raise exception 'Resultado inválido'; end if;
end;
$$;
revoke all on function public.resolve_report(uuid,jsonb,text) from public,anon;
grant execute on function public.resolve_report(uuid,jsonb,text) to authenticated;
