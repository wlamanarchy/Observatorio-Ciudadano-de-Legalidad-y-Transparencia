-- Contexto inicial neutral para abrir el piloto sin precargar soluciones políticas.
-- No crea votos ni preferencias. Requiere 001-007.

insert into public.participation_processes(
  title,process_type,legal_nature,scope_level,status,rules,opens_at
)
select
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
where not exists(
  select 1 from public.participation_processes
  where title='Visión Colombia 2050 — construcción ciudadana piloto'
);

insert into public.diagnostics(
  process_id,title,description,baseline,source_url,observatory_reference
)
select
  p.id,
  'Diagnóstico abierto de retos y oportunidades para Colombia 2050',
  'Punto de partida plural para identificar problemas, capacidades y oportunidades. Puede incorporar evidencia oficial, territorial, académica y hallazgos públicos del Observatorio, todos sujetos a trazabilidad y revisión.',
  jsonb_build_object(
    'status','abierto',
    'method','evidencia pública + experiencia ciudadana + contraste técnico',
    'solutions_preselected',false
  ),
  'https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/',
  'Plataforma hermana: Observatorio Ciudadano de Legalidad y Transparencia'
from public.participation_processes p
where p.title='Visión Colombia 2050 — construcción ciudadana piloto'
  and not exists(
    select 1 from public.diagnostics d
    where d.process_id=p.id
      and d.title='Diagnóstico abierto de retos y oportunidades para Colombia 2050'
  );

insert into public.diagnostic_sources(
  diagnostic_id,source_system,source_record_id,source_url,source_version,source_hash,
  source_published_at,integrity_status,public_payload
)
select
  d.id,
  'observatorio_ciudadano_legalidad_transparencia',
  'public-home',
  'https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/',
  'public',
  encode(digest(convert_to(jsonb_build_object(
    'source','Observatorio Ciudadano de Legalidad y Transparencia',
    'purpose','Fuente hermana para antecedentes públicos de diagnóstico',
    'import_rule','Solo información pública; nunca datos privados o notas internas'
  )::text,'UTF8'),'sha256'),'hex'),
  now(),
  'verified',
  jsonb_build_object(
    'source','Observatorio Ciudadano de Legalidad y Transparencia',
    'purpose','Fuente hermana para antecedentes públicos de diagnóstico',
    'import_rule','Solo información pública; nunca datos privados o notas internas'
  )
from public.diagnostics d
join public.participation_processes p on p.id=d.process_id
where p.title='Visión Colombia 2050 — construcción ciudadana piloto'
  and d.title='Diagnóstico abierto de retos y oportunidades para Colombia 2050'
  and not exists(
    select 1 from public.diagnostic_sources s
    where s.diagnostic_id=d.id
      and s.source_system='observatorio_ciudadano_legalidad_transparencia'
      and s.source_url='https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/'
  );

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
where not exists(
  select 1 from public.algorithm_register
  where name='Orden cronológico del piloto'
);
