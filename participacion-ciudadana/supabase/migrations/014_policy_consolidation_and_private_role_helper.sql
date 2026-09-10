-- Consolida políticas permisivas y mueve la lógica privilegiada de roles fuera del API público.
-- Requiere 001-013.

create index if not exists bootstrap_tokens_consumed_by_idx on private.bootstrap_tokens(consumed_by);

create or replace function private.has_governance_role(
  p_user uuid,p_roles text[],p_institution_id uuid default null,p_process_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path=public,private,pg_temp
as $$
  select exists(
    select 1 from public.governance_roles r
    where r.user_id=p_user
      and r.active
      and (r.expires_at is null or r.expires_at>now())
      and (
        r.role='platform_admin'
        or (
          r.role=any(p_roles)
          and (
            (r.process_id is null and r.institution_id is null)
            or (p_process_id is not null and r.process_id=p_process_id)
            or (p_institution_id is not null and r.institution_id=p_institution_id)
            or (
              p_process_id is not null and r.institution_id is not null and exists(
                select 1 from public.participation_processes p
                where p.id=p_process_id and p.institution_id=r.institution_id
              )
            )
          )
        )
      )
  );
$$;
revoke all on function private.has_governance_role(uuid,text[],uuid,uuid) from public,anon;
grant execute on function private.has_governance_role(uuid,text[],uuid,uuid) to authenticated;
grant usage on schema private to authenticated;

create or replace function public.has_governance_role(
  p_roles text[],p_institution_id uuid default null,p_process_id uuid default null
)
returns boolean
language sql
stable
security invoker
set search_path=public,private,pg_temp
as $$
  select private.has_governance_role(auth.uid(),p_roles,p_institution_id,p_process_id);
$$;
revoke all on function public.has_governance_role(text[],uuid,uuid) from public,anon;
grant execute on function public.has_governance_role(text[],uuid,uuid) to authenticated;

-- Helpers internos: solo son llamados por funciones privilegiadas/trigger, no por clientes.
revoke all on function public.lock_process_rules(uuid) from public,anon,authenticated;
revoke all on function public.freeze_ballot(uuid) from public,anon,authenticated;

-- algorithm_register: una sola política SELECT; mutaciones separadas.
drop policy if exists algorithm_register_admin_all on public.algorithm_register;
drop policy if exists algorithm_register_admin_insert on public.algorithm_register;
drop policy if exists algorithm_register_admin_update on public.algorithm_register;
drop policy if exists algorithm_register_admin_delete on public.algorithm_register;
create policy algorithm_register_admin_insert on public.algorithm_register for insert to authenticated
with check(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']));
create policy algorithm_register_admin_update on public.algorithm_register for update to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']))
with check(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']));
create policy algorithm_register_admin_delete on public.algorithm_register for delete to authenticated
using(public.has_governance_role(array['platform_admin','methodology_admin','independent_auditor']));

-- ballot_options: lectura pública única; mutaciones separadas por gobierno.
drop policy if exists ballot_options_governance_all on public.ballot_options;
drop policy if exists ballot_options_governance_insert on public.ballot_options;
drop policy if exists ballot_options_governance_update on public.ballot_options;
drop policy if exists ballot_options_governance_delete on public.ballot_options;
create policy ballot_options_governance_insert on public.ballot_options for insert to authenticated
with check(exists(select 1 from public.ballots b where b.id=ballot_options.ballot_id and public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,b.process_id)));
create policy ballot_options_governance_update on public.ballot_options for update to authenticated
using(exists(select 1 from public.ballots b where b.id=ballot_options.ballot_id and public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,b.process_id)))
with check(exists(select 1 from public.ballots b where b.id=ballot_options.ballot_id and public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,b.process_id)));
create policy ballot_options_governance_delete on public.ballot_options for delete to authenticated
using(exists(select 1 from public.ballots b where b.id=ballot_options.ballot_id and public.has_governance_role(array['platform_admin','methodology_admin','institution_admin','process_facilitator'],null,b.process_id)));

-- governance_roles: las mutaciones pasan únicamente por RPC auditadas.
drop policy if exists governance_roles_platform_admin_all on public.governance_roles;
drop policy if exists governance_roles_self_read on public.governance_roles;

-- moderation_actions e incidents: una sola lectura pública sanitizada por privilegios de columna.
drop policy if exists moderation_actions_internal_read on public.moderation_actions;
drop policy if exists incidents_authorized_read on public.participation_incidents;
