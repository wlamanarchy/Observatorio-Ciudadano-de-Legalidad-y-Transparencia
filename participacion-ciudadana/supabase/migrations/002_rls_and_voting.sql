alter table public.citizen_profiles enable row level security;
alter table public.institutions enable row level security;
alter table public.participation_processes enable row level security;
alter table public.diagnostics enable row level security;
alter table public.proposals enable row level security;
alter table public.proposal_versions enable row level security;
alter table public.contributions enable row level security;
alter table public.technical_evaluations enable row level security;
alter table public.ballots enable row level security;
alter table public.ballot_options enable row level security;
alter table public.ballot_eligibility enable row level security;
alter table public.ballot_votes enable row level security;
alter table public.institutional_responses enable row level security;
alter table public.implementation_milestones enable row level security;
alter table public.audit_events enable row level security;

create policy institutions_public_read on public.institutions for select using(active=true);
create policy processes_public_read on public.participation_processes for select using(status<>'draft');
create policy diagnostics_public_read on public.diagnostics for select using(true);
create policy proposals_public_read on public.proposals for select using(status<>'draft');
create policy proposal_versions_public_read on public.proposal_versions for select using(true);
create policy contributions_public_read on public.contributions for select using(status='visible');
create policy evaluations_public_read on public.technical_evaluations for select using(true);
create policy ballots_public_read on public.ballots for select using(status in ('open','closed','audited','certified'));
create policy ballot_options_public_read on public.ballot_options for select using(true);
create policy responses_public_read on public.institutional_responses for select using(true);
create policy milestones_public_read on public.implementation_milestones for select using(true);

create policy profiles_self_read on public.citizen_profiles for select to authenticated using(id=(select auth.uid()));
create policy profiles_self_update on public.citizen_profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy proposals_auth_insert on public.proposals for insert to authenticated with check(created_by=(select auth.uid()));
create policy contributions_auth_insert on public.contributions for insert to authenticated with check(created_by=(select auth.uid()));
create policy eligibility_self_read on public.ballot_eligibility for select to authenticated using(user_id=(select auth.uid()));

revoke all on public.ballot_votes from anon, authenticated;
revoke all on public.ballot_eligibility from anon;

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
begin
  if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
  select * into b from public.ballots where id=p_ballot_id for update;
  if not found or b.status<>'open' then raise exception 'Votación no disponible'; end if;
  if b.opens_at is not null and now()<b.opens_at then raise exception 'Votación aún no abierta'; end if;
  if b.closes_at is not null and now()>b.closes_at then raise exception 'Votación cerrada'; end if;
  select * into e from public.ballot_eligibility where ballot_id=p_ballot_id and user_id=auth.uid() for update;
  if not found or not e.eligible then raise exception 'Persona no habilitada'; end if;
  if e.voted_at is not null then raise exception 'Ya registró participación en esta votación'; end if;
  if not exists(select 1 from public.citizen_profiles p where p.id=auth.uid() and p.active and p.verification_level>=b.verification_required) then
    raise exception 'Nivel de verificación insuficiente';
  end if;
  insert into public.ballot_votes(ballot_id,receipt_hash,selection) values(p_ballot_id,receipt,p_selection);
  update public.ballot_eligibility set voted_at=now() where ballot_id=p_ballot_id and user_id=auth.uid();
  insert into public.audit_events(actor_id,event_type,object_type,object_id,metadata)
  values(auth.uid(),'ballot_cast','ballot',p_ballot_id,jsonb_build_object('receipt_hash',receipt));
  return receipt;
end;
$$;
revoke all on function public.cast_ballot(uuid,jsonb) from public, anon;
grant execute on function public.cast_ballot(uuid,jsonb) to authenticated;

create or replace view public.ballot_turnout as
select b.id ballot_id,b.title,b.method,
       count(be.user_id) filter(where be.eligible) eligible_count,
       count(be.user_id) filter(where be.voted_at is not null) participant_count,
       count(v.id) vote_count
from public.ballots b
left join public.ballot_eligibility be on be.ballot_id=b.id
left join public.ballot_votes v on v.ballot_id=b.id
group by b.id,b.title,b.method;

grant select on public.ballot_turnout to anon,authenticated;
