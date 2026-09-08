-- Observatorio Ciudadano de Legalidad y Transparencia
-- Identificador interno de desarrollo: 3.0. El nombre público no cambia.
-- Aplicar en un proyecto Supabase nuevo antes de habilitar reportes reales.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  global_role text check (global_role in ('admin_nacional','curador_nacional','lector_interno')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.territorial_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('coordinador_regional','curador_territorial','lector_territorial')),
  region text,
  department text,
  municipality text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(user_id, role, region, department, municipality)
);

create table if not exists public.findings (
  id uuid primary key default gen_random_uuid(),
  folio bigint generated always as identity unique,
  level text not null default 'nacional' check (level in ('nacional','departamental','distrital','municipal','regional')),
  region text,
  department text,
  municipality text,
  territory text,
  entity_name text not null,
  act_type text not null,
  act_id text not null,
  act_date date,
  finding_class text not null check (finding_class in ('legalidad','integridad','conforme')),
  verification_status text not null default 'sinverificar' check (verification_status in ('documentado','verificacion','sinverificar')),
  replica_status text not null default 'no_notificado' check (replica_status in ('no_notificado','notificado','respondido','no_aplica')),
  published boolean not null default false,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists findings_scope_idx on public.findings(level, region, department, municipality);
create index if not exists findings_public_idx on public.findings(published, act_date desc);
create index if not exists findings_class_idx on public.findings(finding_class, verification_status, replica_status);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  received_at timestamptz not null default now(),
  status text not null default 'received' check (status in ('received','triage','verification','promoted','discarded','archived')),
  level text not null default 'nacional' check (level in ('nacional','departamental','distrital','municipal','regional')),
  region text,
  department text,
  municipality text,
  territory text,
  entity_name text not null,
  act_type text not null,
  act_id text not null,
  act_date date,
  class_hint text check (class_hint in ('legalidad','integridad','conforme')),
  payload jsonb not null default '{}'::jsonb,
  assigned_to uuid references auth.users(id),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reports_queue_idx on public.reports(status, received_at desc);
create index if not exists reports_scope_idx on public.reports(level, region, department, municipality);

create table if not exists public.reporter_private (
  report_id uuid primary key references public.reports(id) on delete cascade,
  contact text,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  table_name text not null,
  record_id uuid,
  action text not null,
  actor uuid,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.has_global_role(roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.active = true and p.global_role = any(roles)
  );
$$;

create or replace function public.can_curate_scope(p_level text, p_region text, p_department text, p_municipality text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.has_global_role(array['admin_nacional','curador_nacional'])
    or exists (
      select 1
      from public.territorial_roles r
      where r.user_id = auth.uid()
        and r.active = true
        and r.role in ('coordinador_regional','curador_territorial')
        and p_level <> 'nacional'
        and (r.region is null or r.region = p_region)
        and (r.department is null or r.department = p_department)
        and (r.municipality is null or r.municipality = p_municipality)
    );
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.audit_row()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_log(table_name, record_id, action, actor, old_data, new_data)
  values (
    tg_table_name,
    coalesce(new.id, old.id),
    tg_op,
    auth.uid(),
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) else null end
  );
  return coalesce(new, old);
end;
$$;

drop trigger if exists findings_touch on public.findings;
drop trigger if exists reports_touch on public.reports;
drop trigger if exists profiles_touch on public.profiles;
drop trigger if exists findings_audit on public.findings;
drop trigger if exists reports_audit on public.reports;
create trigger findings_touch before update on public.findings for each row execute function public.touch_updated_at();
create trigger reports_touch before update on public.reports for each row execute function public.touch_updated_at();
create trigger profiles_touch before update on public.profiles for each row execute function public.touch_updated_at();
create trigger findings_audit after insert or update or delete on public.findings for each row execute function public.audit_row();
create trigger reports_audit after insert or update or delete on public.reports for each row execute function public.audit_row();

alter table public.profiles enable row level security;
alter table public.territorial_roles enable row level security;
alter table public.findings enable row level security;
alter table public.reports enable row level security;
alter table public.reporter_private enable row level security;
alter table public.audit_log enable row level security;

drop policy if exists findings_public_read on public.findings;
drop policy if exists findings_curator_read on public.findings;
drop policy if exists findings_curator_insert on public.findings;
drop policy if exists findings_curator_update on public.findings;
drop policy if exists reports_curator_read on public.reports;
drop policy if exists reports_curator_update on public.reports;
drop policy if exists private_contact_curator_read on public.reporter_private;
drop policy if exists profiles_self_read on public.profiles;
drop policy if exists territorial_roles_self_read on public.territorial_roles;
drop policy if exists audit_admin_read on public.audit_log;

create policy findings_public_read on public.findings
for select using (published = true);

create policy findings_curator_read on public.findings
for select to authenticated
using (public.can_curate_scope(level, region, department, municipality));

create policy findings_curator_insert on public.findings
for insert to authenticated
with check (public.can_curate_scope(level, region, department, municipality));

create policy findings_curator_update on public.findings
for update to authenticated
using (public.can_curate_scope(level, region, department, municipality))
with check (public.can_curate_scope(level, region, department, municipality));

create policy reports_curator_read on public.reports
for select to authenticated
using (public.can_curate_scope(level, region, department, municipality));

create policy reports_curator_update on public.reports
for update to authenticated
using (public.can_curate_scope(level, region, department, municipality))
with check (public.can_curate_scope(level, region, department, municipality));

create policy private_contact_curator_read on public.reporter_private
for select to authenticated
using (
  exists (
    select 1 from public.reports r
    where r.id = reporter_private.report_id
      and public.can_curate_scope(r.level, r.region, r.department, r.municipality)
  )
);

create policy profiles_self_read on public.profiles
for select to authenticated
using (id = auth.uid() or public.has_global_role(array['admin_nacional']));

create policy territorial_roles_self_read on public.territorial_roles
for select to authenticated
using (user_id = auth.uid() or public.has_global_role(array['admin_nacional']));

create policy audit_admin_read on public.audit_log
for select to authenticated
using (public.has_global_role(array['admin_nacional']));

create or replace function public.submit_report(p_report jsonb, p_contact text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := gen_random_uuid();
  v_level text := coalesce(p_report->>'nivel', 'nacional');
begin
  if v_level not in ('nacional','departamental','distrital','municipal','regional') then
    raise exception 'Nivel de vigilancia inválido';
  end if;
  if length(trim(coalesce(p_report->>'entidad',''))) < 2 then
    raise exception 'Entidad requerida';
  end if;
  if length(trim(coalesce(p_report->>'actoId',''))) < 2 then
    raise exception 'Identificación del acto requerida';
  end if;
  if length(trim(coalesce(p_report->>'hecho',''))) < 40 then
    raise exception 'Relato demasiado corto';
  end if;

  insert into public.reports(
    id, level, region, department, municipality, territory,
    entity_name, act_type, act_id, act_date, class_hint, payload
  ) values (
    v_id,
    v_level,
    nullif(p_report->>'region',''),
    nullif(p_report->>'departamento',''),
    nullif(p_report->>'municipio',''),
    nullif(p_report->>'territorio',''),
    p_report->>'entidad',
    coalesce(p_report->>'actoTipo','Actuación'),
    p_report->>'actoId',
    nullif(p_report->>'fecha','')::date,
    nullif(p_report->>'clase',''),
    p_report - 'contacto'
  );

  if p_contact is not null and length(trim(p_contact)) > 0 then
    insert into public.reporter_private(report_id, contact) values (v_id, p_contact);
  end if;

  return v_id;
end;
$$;

grant execute on function public.submit_report(jsonb, text) to anon, authenticated;

create or replace function public.resolve_report(p_report_id uuid, p_finding jsonb, p_outcome text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.reports%rowtype;
  v_finding_id uuid;
begin
  select * into r from public.reports where id = p_report_id for update;
  if not found then raise exception 'Reporte no encontrado'; end if;
  if not public.can_curate_scope(r.level, r.region, r.department, r.municipality) then
    raise exception 'Sin competencia de curaduría para este territorio';
  end if;

  if p_outcome = 'promoted' then
    if p_finding is null then raise exception 'Ficha requerida'; end if;
    v_finding_id := gen_random_uuid();
    insert into public.findings(
      id, level, region, department, municipality, territory, entity_name,
      act_type, act_id, act_date, finding_class, verification_status,
      replica_status, published, payload, created_by, updated_by
    ) values (
      v_finding_id,
      coalesce(p_finding->>'nivel', r.level),
      nullif(p_finding->>'region',''),
      nullif(p_finding->>'departamento',''),
      nullif(p_finding->>'municipio',''),
      nullif(p_finding->>'territorio',''),
      coalesce(p_finding->>'entidad', r.entity_name),
      coalesce(p_finding->>'actoTipo', r.act_type),
      coalesce(p_finding->>'actoId', r.act_id),
      coalesce(nullif(p_finding->>'fecha','')::date, r.act_date),
      coalesce(p_finding->>'clase', r.class_hint, 'integridad'),
      coalesce(p_finding->>'verificacion', 'verificacion'),
      coalesce(p_finding->>'replica', 'no_notificado'),
      false,
      p_finding || jsonb_build_object('id', v_finding_id),
      auth.uid(), auth.uid()
    );
    update public.reports set status='promoted', resolved_at=now(), resolved_by=auth.uid() where id=p_report_id;
  elsif p_outcome = 'discarded' then
    update public.reports set status='discarded', resolved_at=now(), resolved_by=auth.uid() where id=p_report_id;
  else
    raise exception 'Resultado inválido';
  end if;
end;
$$;

grant execute on function public.resolve_report(uuid, jsonb, text) to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, display_name, global_role)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)), null)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
