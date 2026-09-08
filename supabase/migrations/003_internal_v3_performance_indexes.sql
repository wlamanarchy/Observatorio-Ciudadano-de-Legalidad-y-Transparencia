create index if not exists case_events_actor_idx on public.case_events(actor);
create index if not exists findings_created_by_idx on public.findings(created_by);
create index if not exists findings_updated_by_idx on public.findings(updated_by);
create index if not exists replicas_created_by_idx on public.replicas(created_by);
create index if not exists replicas_finding_idx on public.replicas(finding_id);
create index if not exists replicas_updated_by_idx on public.replicas(updated_by);
create index if not exists reports_assigned_to_idx on public.reports(assigned_to);
create index if not exists reports_resolved_by_idx on public.reports(resolved_by);
create index if not exists sources_created_by_idx on public.sources(created_by);
create index if not exists sources_verified_by_idx on public.sources(verified_by);
create index if not exists transfers_created_by_idx on public.transfers(created_by);
create index if not exists transfers_finding_idx on public.transfers(finding_id);
create index if not exists transfers_updated_by_idx on public.transfers(updated_by);

drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
for select to authenticated
using (id = (select auth.uid()) or public.has_global_role(array['admin_nacional']));

drop policy if exists territorial_roles_self_read on public.territorial_roles;
create policy territorial_roles_self_read on public.territorial_roles
for select to authenticated
using (user_id = (select auth.uid()) or public.has_global_role(array['admin_nacional']));
