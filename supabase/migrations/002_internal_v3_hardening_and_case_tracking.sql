create schema if not exists private;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.audit_row() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.touch_updated_at() from public, anon, authenticated;
revoke all on function public.resolve_report(uuid, jsonb, text) from public, anon;
revoke all on function public.submit_report(jsonb, text) from public;
revoke all on function public.has_global_role(text[]) from public, anon;
revoke all on function public.can_curate_scope(text, text, text, text) from public, anon;

grant execute on function public.submit_report(jsonb, text) to anon, authenticated;
grant execute on function public.resolve_report(uuid, jsonb, text) to authenticated;
grant execute on function public.has_global_role(text[]) to authenticated;
grant execute on function public.can_curate_scope(text, text, text, text) to authenticated;

create table if not exists public.sources (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references public.findings(id) on delete cascade,
  source_type text not null,
  title text,
  url text,
  reference text,
  is_primary boolean not null default false,
  is_public boolean not null default true,
  verified boolean not null default false,
  verified_by uuid references auth.users(id),
  verified_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists sources_finding_idx on public.sources(finding_id, is_primary, verified);

create table if not exists public.replicas (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references public.findings(id) on delete cascade,
  recipient text not null,
  sent_at timestamptz,
  due_at timestamptz,
  filing_id text,
  status text not null default 'pendiente' check (status in ('pendiente','enviado','respondido','vencido','cerrado','no_aplica')),
  response_at timestamptz,
  response_summary text,
  document_url text,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists replicas_due_idx on public.replicas(status, due_at);

create table if not exists public.transfers (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references public.findings(id) on delete cascade,
  authority text not null,
  transfer_type text not null default 'traslado',
  sent_at timestamptz,
  due_at timestamptz,
  filing_id text,
  status text not null default 'pendiente' check (status in ('pendiente','radicado','en_tramite','respondido','vencido','cerrado')),
  response_at timestamptz,
  response_summary text,
  document_url text,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists transfers_due_idx on public.transfers(status, due_at);

create table if not exists public.case_events (
  id bigint generated always as identity primary key,
  finding_id uuid not null references public.findings(id) on delete cascade,
  event_type text not null,
  detail jsonb not null default '{}'::jsonb,
  actor uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists case_events_finding_idx on public.case_events(finding_id, created_at desc);

alter table public.sources enable row level security;
alter table public.replicas enable row level security;
alter table public.transfers enable row level security;
alter table public.case_events enable row level security;

create or replace function public.can_curate_finding(p_finding_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.findings f
    where f.id = p_finding_id
      and public.can_curate_scope(f.level, f.region, f.department, f.municipality)
  );
$$;
revoke all on function public.can_curate_finding(uuid) from public, anon;
grant execute on function public.can_curate_finding(uuid) to authenticated;

create policy sources_public_read on public.sources
for select using (
  is_public = true and exists (
    select 1 from public.findings f where f.id = sources.finding_id and f.published = true
  )
);
create policy sources_curator_all on public.sources
for all to authenticated
using (public.can_curate_finding(finding_id))
with check (public.can_curate_finding(finding_id));

create policy replicas_curator_all on public.replicas
for all to authenticated
using (public.can_curate_finding(finding_id))
with check (public.can_curate_finding(finding_id));

create policy transfers_curator_all on public.transfers
for all to authenticated
using (public.can_curate_finding(finding_id))
with check (public.can_curate_finding(finding_id));

create policy case_events_curator_read on public.case_events
for select to authenticated
using (public.can_curate_finding(finding_id));
create policy case_events_curator_insert on public.case_events
for insert to authenticated
with check (public.can_curate_finding(finding_id));

create trigger replicas_touch before update on public.replicas for each row execute function public.touch_updated_at();
create trigger transfers_touch before update on public.transfers for each row execute function public.touch_updated_at();

create or replace view public.pending_deadlines
with (security_invoker = true)
as
select 'replica'::text as item_type, r.id, r.finding_id, r.due_at, r.status, r.recipient as counterparty
from public.replicas r
where r.due_at is not null and r.status in ('pendiente','enviado')
union all
select 'traslado'::text as item_type, t.id, t.finding_id, t.due_at, t.status, t.authority as counterparty
from public.transfers t
where t.due_at is not null and t.status in ('pendiente','radicado','en_tramite');

grant select on public.pending_deadlines to authenticated;

create trigger sources_audit after insert or update or delete on public.sources for each row execute function public.audit_row();
create trigger replicas_audit after insert or update or delete on public.replicas for each row execute function public.audit_row();
create trigger transfers_audit after insert or update or delete on public.transfers for each row execute function public.audit_row();
