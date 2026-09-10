create extension if not exists pgcrypto;

create table if not exists public.citizen_profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  verification_level smallint not null default 1 check (verification_level between 0 and 4),
  municipality text, department text, region text,
  active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.institutions(
  id uuid primary key default gen_random_uuid(),
  name text not null, institution_type text not null,
  territorial_level text, region text, department text, municipality text,
  official_url text, active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.participation_processes(
  id uuid primary key default gen_random_uuid(),
  institution_id uuid references public.institutions(id),
  title text not null, process_type text not null,
  legal_nature text not null default 'consultivo',
  scope_level text not null default 'nacional', region text, department text, municipality text,
  status text not null default 'draft' check(status in ('draft','diagnostic','deliberation','evaluation','prioritization','voting','response','implementation','closed')),
  rules jsonb not null default '{}'::jsonb,
  rules_locked_at timestamptz,
  opens_at timestamptz, closes_at timestamptz,
  created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.diagnostics(
  id uuid primary key default gen_random_uuid(), process_id uuid references public.participation_processes(id) on delete cascade,
  title text not null, description text not null, baseline jsonb not null default '{}'::jsonb,
  source_url text, observatory_reference text, created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.proposals(
  id uuid primary key default gen_random_uuid(), process_id uuid references public.participation_processes(id) on delete cascade,
  diagnostic_id uuid references public.diagnostics(id), title text not null, summary text not null,
  problem text not null, expected_outcome text, theme text, scope_level text, region text, department text, municipality text,
  status text not null default 'draft' check(status in ('draft','published','deliberation','evaluation','eligible','voting','prioritized','not_prioritized','withdrawn','implemented')),
  created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.proposal_versions(
  id bigint generated always as identity primary key, proposal_id uuid not null references public.proposals(id) on delete cascade,
  version_no integer not null, content jsonb not null, change_note text, created_by uuid references auth.users(id), created_at timestamptz not null default now(),
  unique(proposal_id,version_no)
);

create table if not exists public.contributions(
  id uuid primary key default gen_random_uuid(), proposal_id uuid not null references public.proposals(id) on delete cascade,
  contribution_type text not null check(contribution_type in ('supporting_argument','opposing_argument','alternative','question','amendment','evidence')),
  body text not null, source_url text, status text not null default 'visible', created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.technical_evaluations(
  id uuid primary key default gen_random_uuid(), proposal_id uuid not null references public.proposals(id) on delete cascade,
  dimension text not null, assessment text not null, rating text, evidence_url text,
  evaluator_id uuid references auth.users(id), conflict_declared boolean not null default false, created_at timestamptz not null default now()
);

create table if not exists public.ballots(
  id uuid primary key default gen_random_uuid(), process_id uuid not null references public.participation_processes(id) on delete cascade,
  title text not null, method text not null check(method in ('approval','ranked','yes_no','points100','participatory_budget')),
  rules jsonb not null, verification_required smallint not null default 1,
  status text not null default 'draft' check(status in ('draft','open','closed','audited','certified')),
  opens_at timestamptz, closes_at timestamptz, created_at timestamptz not null default now()
);

create table if not exists public.ballot_options(
  id uuid primary key default gen_random_uuid(), ballot_id uuid not null references public.ballots(id) on delete cascade,
  proposal_id uuid references public.proposals(id), label text not null, sort_order int not null default 0
);

create table if not exists public.ballot_eligibility(
  ballot_id uuid not null references public.ballots(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  eligible boolean not null default true, voted_at timestamptz,
  primary key(ballot_id,user_id)
);

create table if not exists public.ballot_votes(
  id uuid primary key default gen_random_uuid(), ballot_id uuid not null references public.ballots(id) on delete cascade,
  receipt_hash text not null unique, selection jsonb not null, cast_at timestamptz not null default now()
);

create table if not exists public.institutional_responses(
  id uuid primary key default gen_random_uuid(), proposal_id uuid not null references public.proposals(id) on delete cascade,
  institution_id uuid references public.institutions(id), response_type text not null,
  rationale text not null, official_reference text, response_date date, created_at timestamptz not null default now()
);

create table if not exists public.implementation_milestones(
  id uuid primary key default gen_random_uuid(), proposal_id uuid not null references public.proposals(id) on delete cascade,
  title text not null, indicator text, baseline numeric, target numeric, current_value numeric,
  due_date date, status text not null default 'planned', evidence_url text, updated_at timestamptz not null default now()
);

create table if not exists public.audit_events(
  id bigint generated always as identity primary key, actor_id uuid, event_type text not null, object_type text not null,
  object_id uuid, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

create index if not exists proposals_scope_idx on public.proposals(scope_level,region,department,municipality,status);
create index if not exists contributions_proposal_idx on public.contributions(proposal_id,created_at);
create index if not exists ballot_votes_ballot_idx on public.ballot_votes(ballot_id,cast_at);
create index if not exists milestones_due_idx on public.implementation_milestones(status,due_date);
