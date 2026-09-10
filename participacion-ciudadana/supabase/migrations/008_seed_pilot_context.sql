-- Contexto inicial neutral para abrir el piloto sin precargar soluciones políticas.
-- No crea votos ni preferencias. Requiere 001-007.

do $$
declare
  v_process uuid;
  v_diag uuid;
  v_obs_url text := 'https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/';
  v_payload jsonb := jsonb_build_object(
    'source','Observatorio Ciudadano de Legalidad y Transparencia',
    'purpose','Fuente hermana para antecedentes públicos de diagnóstico',
    'import_rule','Solo información pública; nunca datos privados o notas internas'
  );
begin
  select id into v_process
  from public.participation_processes
  where title='Visión Colombia 2050 — construcción ciudadana piloto'
  order by created_at asc limit 1;

  if v_process is null then
    insert into public.participation_processes(
      title,process_type,legal_nature,scope_level,status,rules,opens_at
    ) values (
      'Visión Colombia 2050 — construcción ciudadana piloto',
      'vision_largo_plazo',
      'consultivo',
      'nacional',
      'deliberation',
      jsonb_build_object(
        'pilot',true,
        'purpose','Construir y priorizar propuestas de futuro para Colombia mediante diagnóstico, deliberación, evaluación y participación trazable',
        'binding_effect',false,
        'participation_principles',jsonb_build_array(
          'igualdad política','pluralismo','trazabilidad','accesibilidad','protección de datos','deliberación informada','retroalimentación institucional'
        ),
        'consensus_rule','No se presume consenso por mayoría simple; cada votación debe publicar umbrales y alcance antes de abrirse',
        'diagnostic_source_policy','Los hallazgos del Observatorio son insumos públicos de diagnóstico, no soluciones automáticas'
      ),
      now()
    ) returning id into v_process;
  end if;

  select id into v_diag
  from public.diagnostics
  where process_id=v_process and title='Diagnóstico abierto de retos y oportunidades para Colombia 2050'
  order by created_at asc limit 1;

  if v_diag is null then
    insert into public.diagnostics(
      process_id,title,description,baseline,source_url,observatory_reference
    ) values (
      v_process,
      'Diagnóstico abierto de retos y oportunidades para Colombia 2050',
      'Punto de partida plural para identificar problemas, capacidades y oportunidades. Puede incorporar evidencia oficial, territorial, académica y hallazgos públicos del Observatorio, todos sujetos a trazabilidad y revisión.',
      jsonb_build_object(
        'status','abierto',
        'method','evidencia pública + experiencia ciudadana + contraste técnico',
        'solutions_preselected',false
      ),
      v_obs_url,
      'Plataforma hermana: Observatorio Ciudadano de Legalidad y Transparencia'
    ) returning id into v_diag;
  end if;

  if not exists(
    select 1 from public.diagnostic_sources
    where diagnostic_id=v_diag and source_system='observatorio_ciudadano_legalidad_transparencia'
      and source_url=v_obs_url
  ) then
    insert into public.diagnostic_sources(
      diagnostic_id,source_system,source_record_id,source_url,source_version,source_hash,
      source_published_at,integrity_status,public_payload
    ) values (
      v_diag,
      'observatorio_ciudadano_legalidad_transparencia',
      'public-home',
      v_obs_url,
      'public',
      encode(digest(convert_to(v_payload::text,'UTF8'),'sha256'),'hex'),
      now(),
      'verified',
      v_payload
    );
  end if;
end;
$$;

insert into public.algorithm_register(
  name,purpose,affected_features,input_categories,ranking_or_decision_effect,human_oversight,appeal_mechanism,source_repository,source_commit,risk_level,active
)
select
  'Orden cronológico del piloto',
  'Presentar inicialmente procesos, propuestas y aportes sin personalización política.',
  array['directorio de procesos','feed de propuestas','aportes'],
  array['fecha de creación','estado público'],
  'No altera votos, no otorga puntajes y no decide prioridades; solo ordena contenido público por fecha.',
  'Revisión metodológica y auditoría del código abierto.',
  'Cualquier participante puede reportar un sesgo o error de presentación para revisión pública.',
  'https://github.com/wlamanarchy/Observatorio-Ciudadano-de-Legalidad-y-Transparencia',
  null,
  'low',
  true
where not exists(select 1 from public.algorithm_register where name='Orden cronológico del piloto');
