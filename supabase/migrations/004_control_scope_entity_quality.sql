-- Observatorio Ciudadano de Legalidad y Transparencia
-- Expansión de ámbitos, entidades y controles de publicación.

create table if not exists public.control_scope_type_catalog (
  code text primary key,
  name text not null,
  family text not null,
  is_ethnic_territorial boolean not null default false,
  is_special_control_scope boolean not null default false,
  control_notes text not null,
  normative_basis text[] not null default '{}',
  official_reference_url text,
  sort_order integer not null default 1000,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.control_scope_type_catalog enable row level security;
drop policy if exists control_scope_catalog_public_read on public.control_scope_type_catalog;
create policy control_scope_catalog_public_read on public.control_scope_type_catalog for select using (active=true);
revoke insert,update,delete on public.control_scope_type_catalog from anon,authenticated;
grant select on public.control_scope_type_catalog to anon,authenticated;

create table if not exists public.control_entity_type_catalog (
  code text primary key,
  name text not null,
  family text not null,
  branch_or_system text not null,
  governance_level text,
  is_state_entity boolean not null default true,
  is_collective_governance boolean not null default false,
  control_focus text not null,
  normative_basis text[] not null default '{}',
  official_reference_url text,
  notes text,
  sort_order integer not null default 1000,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.control_entity_type_catalog enable row level security;
drop policy if exists control_entity_catalog_public_read on public.control_entity_type_catalog;
create policy control_entity_catalog_public_read on public.control_entity_type_catalog for select using (active=true);
revoke insert,update,delete on public.control_entity_type_catalog from anon,authenticated;
grant select on public.control_entity_type_catalog to anon,authenticated;

create table if not exists public.control_route_catalog (
  code text primary key,
  name text not null,
  family text not null,
  when_to_use text not null,
  authority_hint text not null,
  normative_basis text[] not null default '{}',
  notes text,
  sort_order integer not null default 1000,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.control_route_catalog enable row level security;
drop policy if exists control_route_catalog_public_read on public.control_route_catalog;
create policy control_route_catalog_public_read on public.control_route_catalog for select using(active=true);
revoke insert,update,delete on public.control_route_catalog from anon,authenticated;
grant select on public.control_route_catalog to anon,authenticated;

create table if not exists public.control_reference_registries (
  code text primary key,
  name text not null,
  responsible_authority text not null,
  coverage text not null,
  url text not null,
  use_in_observatory text not null,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.control_reference_registries enable row level security;
drop policy if exists control_reference_registries_public_read on public.control_reference_registries;
create policy control_reference_registries_public_read on public.control_reference_registries for select using(active=true);
revoke insert,update,delete on public.control_reference_registries from anon,authenticated;
grant select on public.control_reference_registries to anon,authenticated;

insert into public.control_scope_type_catalog(code,name,family,is_ethnic_territorial,is_special_control_scope,control_notes,normative_basis,official_reference_url,sort_order) values
('nacional','Colombia / ámbito nacional','Territorial',false,false,'Control de actuaciones, políticas, contratos, normas y gestión de alcance nacional.',array['Constitución Política','Ley 850 de 2003','Ley 1712 de 2014'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',10),
('regional','Región / ámbito supradepartamental','Territorial',false,true,'Control de decisiones, proyectos o actuaciones que comprometen más de un departamento.',array['Ley 1454 de 2011','Ley 1962 de 2019'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',20),
('rap','Región Administrativa y de Planificación','Esquema asociativo territorial',false,true,'Control sobre la gestión, proyectos y decisiones de una RAP constituida.',array['Ley 1454 de 2011','Ley 1962 de 2019'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',21),
('departamental','Departamento','Territorial',false,false,'Control de gobernación, asamblea, entidades descentralizadas y demás sujetos departamentales.',array['Constitución Política','Ley 850 de 2003'],'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',30),
('distrital','Distrito','Territorial',false,false,'Control de administración distrital, concejo y entidades del distrito.',array['Constitución Política','Ley 850 de 2003'],'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',40),
('municipal','Municipio','Territorial',false,false,'Control de alcaldía, concejo, establecimientos, fondos y demás sujetos municipales.',array['Constitución Política','Ley 136 de 1994','Ley 850 de 2003'],'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',50),
('localidad','Localidad','Local',false,true,'Control de fondos, alcaldías y decisiones locales cuando el régimen territorial las contemple.',array['Régimen distrital o municipal aplicable','Ley 850 de 2003'],null,60),
('comuna','Comuna','Local',false,true,'Ámbito submunicipal para seguimiento de inversión, compromisos y planeación participativa.',array['Ley 136 de 1994','Ley 1757 de 2015'],null,61),
('corregimiento','Corregimiento','Local',false,true,'Ámbito rural o especial submunicipal para control de compromisos, inversión y servicios.',array['Ley 136 de 1994','Ley 850 de 2003'],null,62),
('vereda','Vereda','Local',false,true,'Ámbito comunitario rural; permite documentar ejecución y brechas sin presumir personería territorial.',array['Ley 850 de 2003','Ley 2166 de 2021'],null,63),
('area_metropolitana','Área metropolitana','Esquema asociativo territorial',false,true,'Control de hechos metropolitanos, inversiones y gestión supramunicipal.',array['Ley 1625 de 2013'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=52972',70),
('provincia_administrativa_planificacion','Provincia administrativa y de planificación','Esquema asociativo territorial',false,true,'Control de actuaciones y proyectos de la figura asociativa constituida.',array['Ley 1454 de 2011'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',71),
('pdet_subregion','Subregión PDET','Planeación especial',false,true,'Seguimiento a iniciativas, PATR, hojas de ruta, compromisos y proyectos PDET.',array['Decreto Ley 893 de 2017'],'https://www.renovacionterritorio.gov.co/',72),
('zona_reserva_campesina','Zona de Reserva Campesina','Planeación rural especial',false,true,'Seguimiento al plan de desarrollo sostenible, inversiones y compromisos públicos en ZRC.',array['Ley 160 de 1994','Decreto 1777 de 1996'],'https://www.ant.gov.co/',73),
('cuenca_pomca','Cuenca o unidad hidrográfica de planificación','Planeación ambiental',false,true,'Control de POMCA, determinantes, inversiones y actuaciones de autoridades ambientales.',array['Decreto 1076 de 2015'],'https://www.minambiente.gov.co/',74),
('institucional','Institución pública o autónoma','Institucional',false,true,'Control sobre planes, contratación, normas internas y gestión de universidades, órganos autónomos u otras instituciones.',array['Ley 850 de 2003','Norma orgánica y estatutos de cada institución'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',80),
('resguardo_indigena','Resguardo indígena','Étnico-territorial',true,true,'Control respetuoso del gobierno propio sobre recursos públicos, convenios o actuaciones estatales que incidan en el resguardo. El resguardo no se confunde con su autoridad.',array['Constitución Política arts. 63, 246, 329 y 330','Decreto 1953 de 2014'],'https://www.ant.gov.co/glosario',90),
('territorio_indigena','Territorio indígena','Étnico-territorial',true,true,'Control de actuaciones públicas que incidan en territorios indígenas, preservando competencia y gobierno propio.',array['Decreto 1953 de 2014','Ley 21 de 1991'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=59636',91),
('comunidad_parcialidad_indigena','Comunidad o parcialidad indígena','Étnico-territorial',true,true,'Ámbito para documentar actuaciones que afecten a una comunidad o parcialidad identificada y a sus autoridades.',array['Ley 21 de 1991','Régimen indígena aplicable'],'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',92),
('territorio_ancestral_indigena','Territorio ancestral o tradicional indígena','Étnico-territorial',true,true,'Ámbito de control sobre actuaciones públicas con incidencia territorial o cultural que requieran identificación de autoridad y garantías especiales.',array['Ley 21 de 1991','Régimen de protección territorial indígena'],'https://www.ant.gov.co/',93),
('tierra_colectiva_narp','Tierra o territorio colectivo NARP','Étnico-territorial',true,true,'Control de actuaciones públicas y recursos que incidan en tierras o territorios colectivos, diferenciando territorio de autoridad representativa.',array['Ley 70 de 1993','Decreto 1745 de 1995'],'https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/',94),
('consejo_comunitario_territorio','Ámbito de un consejo comunitario NARP','Étnico-territorial',true,true,'Seguimiento a actuaciones, convenios, recursos y compromisos relacionados con un consejo comunitario y su territorio.',array['Ley 70 de 1993','Decreto 1745 de 1995'],'https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/',95),
('territorio_raizal','Territorio o comunidad raizal','Étnico-territorial',true,true,'Control con enfoque diferencial sobre actuaciones públicas que afecten directamente a la comunidad raizal.',array['Constitución Política','Ley 21 de 1991'],'https://www.mininterior.gov.co/',96),
('territorio_palenquero','Territorio o comunidad palenquera','Étnico-territorial',true,true,'Control con enfoque diferencial sobre actuaciones públicas que afecten directamente a comunidades palenqueras.',array['Ley 70 de 1993','Ley 21 de 1991'],'https://www.mininterior.gov.co/',97),
('kumpania_rom','Kumpania del pueblo Rrom','Étnico-comunitario',true,true,'Control de actuaciones públicas con incidencia en una Kumpania, respetando su representación y régimen propio.',array['Decreto 2957 de 2010'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=40124',98)
on conflict(code) do update set name=excluded.name,family=excluded.family,is_ethnic_territorial=excluded.is_ethnic_territorial,is_special_control_scope=excluded.is_special_control_scope,control_notes=excluded.control_notes,normative_basis=excluded.normative_basis,official_reference_url=excluded.official_reference_url,sort_order=excluded.sort_order,active=true,updated_at=now();

insert into public.control_entity_type_catalog(code,name,family,branch_or_system,governance_level,is_state_entity,is_collective_governance,control_focus,normative_basis,official_reference_url,notes,sort_order) values
('presidencia_republica','Presidencia de la República','Administración nacional','Rama Ejecutiva','Nacional',true,false,'Legalidad, contratación, transparencia, ejecución y cumplimiento de competencias.',array['Constitución Política','Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,10),
('ministerio','Ministerio','Administración nacional','Rama Ejecutiva','Nacional',true,false,'Políticas, regulación, contratación, transferencias, programas y deberes de publicidad.',array['Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,20),
('departamento_administrativo','Departamento administrativo','Administración nacional','Rama Ejecutiva','Nacional',true,false,'Planeación, regulación, contratación y funciones administrativas especializadas.',array['Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,30),
('superintendencia','Superintendencia','Administración nacional','Rama Ejecutiva','Nacional',true,false,'Legalidad de actos, inspección, vigilancia, sanción, contratación y transparencia.',array['Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,40),
('unidad_administrativa_especial','Unidad administrativa especial','Administración nacional','Rama Ejecutiva','Nacional',true,false,'Actos, contratación, ejecución de programas y competencias técnicas especializadas.',array['Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,50),
('agencia_estatal','Agencia estatal / de naturaleza especial','Administración nacional','Rama Ejecutiva','Nacional',true,false,'Ejecución de políticas, programas, inversión, contratación y resultados.',array['Norma de creación de cada agencia'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,60),
('establecimiento_publico','Establecimiento público','Descentralizado','Rama Ejecutiva','Nacional o territorial',true,false,'Gestión administrativa, contratación, presupuesto, servicio y cumplimiento del objeto.',array['Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,70),
('eice','Empresa industrial y comercial del Estado','Descentralizado','Rama Ejecutiva','Nacional o territorial',true,false,'Gestión de recursos públicos, contratación aplicable, gobierno corporativo e integridad.',array['Ley 489 de 1998'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,80),
('sociedad_economia_mixta','Sociedad de economía mixta','Descentralizado','Rama Ejecutiva','Nacional o territorial',true,false,'Uso de recursos públicos, régimen contractual aplicable, gobierno corporativo y transparencia.',array['Ley 489 de 1998','Código de Comercio'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','La intensidad del control depende de participación pública y régimen concreto.',90),
('ese','Empresa Social del Estado','Descentralizado','Rama Ejecutiva','Nacional o territorial',true,false,'Contratación, prestación del servicio, presupuesto, talento humano y resultados en salud.',array['Ley 100 de 1993'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,100),
('esp_oficial_mixta','Empresa de servicios públicos oficial o mixta','Descentralizado','Rama Ejecutiva','Nacional o territorial',true,false,'Calidad, inversión, contratación, tarifas dentro de competencia y gestión de recursos públicos.',array['Ley 142 de 1994'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,110),
('congreso','Congreso de la República','Corporación pública','Rama Legislativa','Nacional',true,false,'Transparencia, contratación, ejecución administrativa y cumplimiento de reglas procedimentales; no sustituye control constitucional.',array['Constitución Política','Ley 5 de 1992'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,200),
('asamblea_departamental','Asamblea departamental','Corporación pública','Rama Legislativa','Departamental',true,false,'Legalidad procedimental, contratación, presupuesto y actos administrativos propios.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,210),
('concejo_municipal_distrital','Concejo municipal o distrital','Corporación pública','Rama Legislativa','Municipal o distrital',true,false,'Acuerdos, contratación, presupuesto y funcionamiento administrativo.',array['Constitución Política','Ley 136 de 1994'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,220),
('junta_administradora_local','Junta Administradora Local','Corporación pública','Rama Legislativa','Local',true,false,'Decisiones locales, priorización, contratación cuando corresponda y ejecución de fondos.',array['Constitución Política','Ley 136 de 1994'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,230),
('altas_cortes','Altas Cortes','Administración de justicia','Rama Judicial','Nacional',true,false,'Control ciudadano sobre administración, presupuesto, contratación y transparencia institucional, no sobre el sentido de decisiones judiciales.',array['Constitución Política','Ley 270 de 1996'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','No se somete la independencia judicial a control político de la plataforma.',300),
('consejo_superior_judicatura','Consejo Superior de la Judicatura','Administración de justicia','Rama Judicial','Nacional',true,false,'Administración judicial, contratación, presupuesto, carrera y ejecución de planes.',array['Constitución Política','Ley 270 de 1996'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,310),
('fiscalia_general','Fiscalía General de la Nación','Administración de justicia','Rama Judicial','Nacional',true,false,'Gestión administrativa, contratación y garantías de servicio; no se publican datos reservados de investigaciones.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','Respetar reserva legal y debido proceso.',320),
('jep','Jurisdicción Especial para la Paz','Sistema Integral de Paz','Sistema Integral de Paz','Nacional',true,false,'Gestión administrativa, contratación, participación y cumplimiento institucional sin interferir la independencia judicial.',array['Acto Legislativo 01 de 2017'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,330),
('procuraduria','Procuraduría General de la Nación','Control','Organismos de Control','Nacional',true,false,'Gestión propia, contratación, transparencia y respuesta a actuaciones ciudadanas.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,400),
('defensoria','Defensoría del Pueblo','Control','Organismos de Control','Nacional',true,false,'Gestión administrativa, contratación, atención y cumplimiento de funciones de derechos humanos.',array['Constitución Política','Ley 24 de 1992'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,410),
('contraloria_general','Contraloría General de la República','Control fiscal','Organismos de Control','Nacional',true,false,'Gestión propia y respuesta al control social, preservando autonomía del control fiscal.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,420),
('auditoria_general','Auditoría General de la República','Control fiscal','Organismos de Control','Nacional',true,false,'Gestión propia y desempeño de vigilancia fiscal sobre contralorías.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,430),
('contraloria_territorial','Contraloría territorial','Control fiscal','Organismos de Control','Territorial',true,false,'Gestión propia y respuesta al control social territorial.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,440),
('personeria','Personería municipal o distrital','Ministerio Público territorial','Organismos de Control','Municipal o distrital',true,false,'Gestión, protección de derechos, acompañamiento al control social y respuestas ciudadanas.',array['Ley 136 de 1994','Ley 850 de 2003'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,450),
('consejo_nacional_electoral','Consejo Nacional Electoral','Organización electoral','Organización Electoral','Nacional',true,false,'Gestión administrativa, contratación, transparencia y actos dentro de competencia.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,500),
('registraduria','Registraduría Nacional del Estado Civil','Organización electoral','Organización Electoral','Nacional',true,false,'Gestión administrativa, contratación y garantías del servicio electoral e identificación.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,510),
('banco_republica','Banco de la República','Autónomo','Órganos Autónomos e Independientes','Nacional',true,false,'Transparencia, contratación y gestión administrativa respetando autonomía constitucional.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,600),
('cnsc','Comisión Nacional del Servicio Civil','Autónomo','Órganos Autónomos e Independientes','Nacional',true,false,'Carrera administrativa, convocatorias, contratación, transparencia y actos de competencia.',array['Constitución Política'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,610),
('car_cds','Corporación Autónoma Regional o de Desarrollo Sostenible','Ambiental','Órganos Autónomos e Independientes','Regional',true,false,'Licenciamiento o permisos según competencia, contratación, POMCA, PGAR, inversiones y transparencia.',array['Ley 99 de 1993'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estado/organos-autonomos.php',null,620),
('universidad_publica','Universidad estatal u oficial / ente universitario autónomo','Educación superior','Órganos Autónomos e Independientes','Nacional o territorial',true,false,'Contratación, presupuesto, gobierno universitario, acceso a información y cumplimiento de estatutos, respetando autonomía universitaria.',array['Constitución Política','Ley 30 de 1992'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,630),
('gobernacion','Gobernación departamental','Gobierno territorial','Rama Ejecutiva','Departamental',true,false,'Plan de desarrollo, contratación, inversión, actos, empleo público y transparencia.',array['Constitución Política','Ley 152 de 1994'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,700),
('alcaldia','Alcaldía municipal o distrital','Gobierno territorial','Rama Ejecutiva','Municipal o distrital',true,false,'Plan de desarrollo, POT, contratación, inversión, actos, empleo público y transparencia.',array['Constitución Política','Ley 136 de 1994','Ley 152 de 1994'],'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,710),
('area_metropolitana','Área metropolitana','Esquema territorial','Régimen territorial','Supramunicipal',true,false,'Hechos metropolitanos, contratación, inversión y planes metropolitanos.',array['Ley 1625 de 2013'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=52972',null,720),
('rap','Región Administrativa y de Planificación','Esquema territorial','Régimen territorial','Regional',true,false,'Planeación regional, contratos, proyectos e inversiones interdepartamentales.',array['Ley 1454 de 2011','Ley 1962 de 2019'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',null,730),
('provincia_administrativa_planificacion','Provincia administrativa y de planificación','Esquema territorial','Régimen territorial','Supramunicipal',true,false,'Planeación, proyectos, convenios y gestión supramunicipal.',array['Ley 1454 de 2011'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',null,740),
('asociacion_entidades_territoriales','Asociación de entidades territoriales','Esquema territorial','Régimen territorial','Supraterritorial',true,false,'Convenios, recursos, servicios y proyectos conjuntos.',array['Ley 1454 de 2011'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',null,750),
('ocad_sgr','Órgano Colegiado de Administración y Decisión del SGR','Regalías','Sistema General de Regalías','Regional o sectorial',true,false,'Priorización, aprobación y seguimiento de proyectos del SGR según el régimen vigente.',array['Ley 2056 de 2020'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=142858',null,760),
('consejo_nacional_planeacion','Consejo Nacional de Planeación','Planeación participativa','Instancia de Participación','Nacional',false,false,'Seguimiento al proceso participativo, publicidad de conceptos y cumplimiento de funciones de planeación.',array['Constitución Política','Ley 152 de 1994'],'https://www.dnp.gov.co/',null,800),
('consejo_territorial_planeacion','Consejo Territorial de Planeación','Planeación participativa','Instancia de Participación','Territorial',false,false,'Seguimiento a participación, conceptos y garantías de planeación territorial.',array['Constitución Política','Ley 152 de 1994'],'https://www.dnp.gov.co/',null,810),
('organismo_accion_comunal','Organismo de acción comunal','Organización ciudadana','Instancia de Participación','Local',false,true,'Seguimiento cuando administre recursos, ejecute convenios o participe en gestión pública; no se presume sujeto estatal.',array['Ley 2166 de 2021'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=184758',null,820),
('veeduria_ciudadana','Veeduría ciudadana','Control social','Instancia de Participación','Todos',false,false,'Seguimiento a su actuación cuando sea fuente, aliada o instancia de control social; no se confunde con autoridad pública.',array['Ley 850 de 2003'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=10570',null,830),
('resguardo_indigena','Resguardo indígena','Gobierno y territorio indígena','Gobierno propio / autonomía étnica','Étnico-territorial',false,true,'Seguimiento diferenciado de recursos públicos, convenios y actuaciones estatales vinculadas al resguardo, sin confundirlo con la autoridad que lo gobierna.',array['Constitución Política','Decreto 1953 de 2014'],'https://www.ant.gov.co/glosario',null,900),
('territorio_indigena_1953','Territorio indígena en funcionamiento','Gobierno y territorio indígena','Gobierno propio / autonomía étnica','Étnico-territorial',false,true,'Seguimiento de competencias públicas asumidas, recursos y convenios conforme al régimen especial.',array['Decreto 1953 de 2014'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=59636',null,910),
('cabildo_indigena','Cabildo indígena','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial',false,true,'Seguimiento de recursos públicos o convenios bajo su administración, respetando derecho propio y autonomía.',array['Decreto 1088 de 1993','Decreto 1953 de 2014'],'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,920),
('autoridad_tradicional_indigena','Autoridad tradicional indígena','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial',false,true,'Control sobre gestión de recursos públicos o interacción con el Estado, con enfoque de competencia y autonomía.',array['Ley 21 de 1991','Decreto 1953 de 2014'],'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,930),
('consejo_indigena_gobierno_propio','Consejo indígena o estructura colectiva de gobierno propio','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial',false,true,'Seguimiento a ejercicio de funciones públicas y recursos cuando corresponda.',array['Decreto 1953 de 2014'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=59636',null,940),
('asociacion_cabildos_autoridades','Asociación de cabildos y/o autoridades tradicionales indígenas','Asociación indígena','Gobierno propio / autonomía étnica','Supraterritorial indígena',false,true,'Seguimiento a convenios, recursos y gestión pública propia del objeto asociativo.',array['Decreto 1088 de 1993'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=1501',null,950),
('asociacion_resguardos_indigenas','Asociación de resguardos indígenas','Asociación indígena','Gobierno propio / autonomía étnica','Supraterritorial indígena',false,true,'Seguimiento diferenciado a proyectos, convenios y recursos bajo su gestión.',array['Régimen especial aplicable'],'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,960),
('consejo_territorial_indigena','Consejo Territorial Indígena','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial',false,true,'Seguimiento a actuaciones públicas o administración de recursos en el alcance que reconozca el régimen aplicable.',array['Régimen especial aplicable'],'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,970),
('consejo_comunitario_narp','Consejo comunitario NARP','Gobierno colectivo NARP','Autonomía étnica y territorio colectivo','Étnico-territorial',false,true,'Seguimiento a recursos, convenios, representación y actuaciones públicas relacionadas con la comunidad y territorio.',array['Ley 70 de 1993','Decreto 1745 de 1995'],'https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/',null,980),
('tierra_colectiva_narp','Tierra o territorio colectivo NARP','Territorio colectivo NARP','Autonomía étnica y territorio colectivo','Étnico-territorial',false,true,'Ámbito de control; la autoridad representativa debe identificarse de manera separada.',array['Ley 70 de 1993','Decreto 1745 de 1995'],'https://www.ant.gov.co/',null,990),
('organizacion_narp','Organización o forma/expresión organizativa NARP','Organización étnica','Participación étnica','Local, territorial o nacional',false,true,'Seguimiento solo cuando gestione recursos públicos, convenios o funciones sujetas a control social.',array['Ley 70 de 1993','Decreto 1066 de 2015'],'https://www.mininterior.gov.co/',null,1000),
('organizacion_segundo_nivel_narp','Organización de segundo nivel NARP','Organización étnica','Participación étnica','Supraterritorial',false,true,'Seguimiento cuando gestione recursos públicos, convenios o representación institucional relevante.',array['Decreto 1066 de 2015'],'https://www.mininterior.gov.co/',null,1010),
('kumpania_rom','Kumpania del pueblo Rrom','Gobierno y organización Rrom','Autonomía étnica Rrom','Étnico-comunitario',false,true,'Seguimiento diferenciado a actuaciones estatales, convenios o recursos relacionados con la Kumpania.',array['Decreto 2957 de 2010'],'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=40124',null,1020),
('organizacion_rom','Organización Rrom registrada','Organización étnica','Autonomía étnica Rrom','Local o nacional',false,true,'Seguimiento cuando gestione recursos públicos, convenios o representación institucional relevante.',array['Decreto 2957 de 2010'],'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,1030),
('otra','Otra entidad, autoridad, instancia u organización sujeta a control social','Otra','Multisistema','Multinivel',false,false,'Determinar primero su naturaleza jurídica, competencia y relación con recursos o gestión pública.',array['Constitución Política art. 270','Ley 850 de 2003'],null,'No presumir competencia ni naturaleza pública sin verificación.',2000)
on conflict(code) do update set name=excluded.name,family=excluded.family,branch_or_system=excluded.branch_or_system,governance_level=excluded.governance_level,is_state_entity=excluded.is_state_entity,is_collective_governance=excluded.is_collective_governance,control_focus=excluded.control_focus,normative_basis=excluded.normative_basis,official_reference_url=excluded.official_reference_url,notes=excluded.notes,sort_order=excluded.sort_order,active=true,updated_at=now();

insert into public.control_route_catalog(code,name,family,when_to_use,authority_hint,normative_basis,notes,sort_order) values
('replica_observatorio','Derecho de réplica del Observatorio','Garantía metodológica','Antes de publicar un hallazgo adverso o cuando se requiera aclaración de la entidad observada.','Entidad, órgano o autoridad directamente observada.',array['Debido proceso metodológico','Ley 850 de 2003'],'No equivale por sí solo a un procedimiento sancionatorio.',10),
('derecho_peticion','Derecho de petición','Información / actuación administrativa','Para solicitar documentos, explicaciones, actuaciones o decisiones dentro de la competencia de una autoridad.','Entidad competente para resolver la petición.',array['Constitución Política art. 23','Ley 1755 de 2015'],null,20),
('acceso_informacion','Acceso a información pública','Transparencia','Cuando se requiera información pública, datos, contratos, actos o soportes sujetos al régimen de transparencia.','Sujeto obligado que posee o controla la información.',array['Ley 1712 de 2014'],null,30),
('control_fiscal','Traslado a control fiscal','Control fiscal','Ante hechos documentados que puedan comprometer gestión o recursos fiscales.','CGR o contraloría territorial según sujeto, recurso y competencia.',array['Constitución Política','Régimen de control fiscal vigente'],'La plataforma no declara responsabilidad fiscal.',40),
('disciplinario','Traslado disciplinario / preventivo','Ministerio Público','Ante hechos documentados potencialmente relevantes para el régimen disciplinario o funciones preventivas.','Procuraduría, personería u oficina competente según sujeto y materia.',array['Constitución Política','Código General Disciplinario'],'La plataforma no declara responsabilidad disciplinaria.',50),
('penal','Traslado penal','Investigación penal','Ante hechos documentados que razonablemente ameriten conocimiento de la autoridad penal.','Fiscalía General de la Nación o autoridad penal competente.',array['Constitución Política','Código Penal y de Procedimiento Penal'],'Evitar afirmaciones de culpabilidad; reportar hechos y soportes.',60),
('derechos_humanos','Ruta de derechos humanos','Garantías y protección','Cuando existan riesgos o afectaciones de derechos que ameriten intervención defensorial o preventiva.','Defensoría del Pueblo, Ministerio Público u otra autoridad de protección competente.',array['Constitución Política','Ley 24 de 1992'],null,70),
('control_politico','Control político','Corporaciones públicas','Para hechos de gestión que deban ser conocidos por corporaciones con competencia de control político.','Congreso, asamblea o concejo según nivel y competencia.',array['Constitución Política'],null,80),
('jurisdiccion_administrativa','Jurisdicción de lo contencioso administrativo','Control judicial','Cuando una persona legitimada evalúe acciones judiciales frente a actos, contratos, omisiones u otras materias administrativas.','Juzgado, tribunal o Consejo de Estado según competencia.',array['Ley 1437 de 2011'],'El Observatorio no sustituye asesoría jurídica ni declara nulidades.',90),
('accion_constitucional_colectiva','Acciones constitucionales o colectivas','Control judicial / derechos','Cuando proceda tutela, cumplimiento, acción popular u otro mecanismo, según legitimación y presupuestos.','Juez competente según mecanismo.',array['Constitución Política','Ley 393 de 1997','Ley 472 de 1998'],'La ruta depende del caso concreto.',100),
('consulta_previa_salvaguarda','Salvaguarda de consulta previa y gobierno propio','Garantía étnica','Cuando una medida o actuación pueda afectar directamente a pueblos o comunidades sujetos de consulta previa.','Autoridad Nacional de Consulta Previa y autoridades representativas correspondientes.',array['Ley 21 de 1991','Normativa especial aplicable'],'No es una ruta sancionatoria. El control ciudadano no sustituye la consulta previa.',110),
('otra_competente','Otra autoridad competente','Especial','Cuando exista una autoridad sectorial, regulatoria, ambiental, electoral o especial con competencia específica.','Autoridad sectorial o especial determinada mediante verificación jurídica.',array['Norma especial aplicable'],'Confirmar competencia antes de radicar.',200)
on conflict(code) do update set name=excluded.name,family=excluded.family,when_to_use=excluded.when_to_use,authority_hint=excluded.authority_hint,normative_basis=excluded.normative_basis,notes=excluded.notes,sort_order=excluded.sort_order,active=true,updated_at=now();

insert into public.control_reference_registries(code,name,responsible_authority,coverage,url,use_in_observatory) values
('dafp_estructura_estado','Manual de Estructura del Estado Colombiano','Departamento Administrativo de la Función Pública','Entidades, órganos, ramas y sistemas del Estado','https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','Clasificar correctamente al sujeto observado y evitar errores de competencia.'),
('dane_divipola','DIVIPOLA','DANE','Departamentos, municipios, distritos y codificación territorial','https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola','Validar jerarquía y código territorial ordinario.'),
('mininterior_indigenas_rom','Registros de autoridades indígenas, resguardos, asociaciones y pueblo Rrom','Ministerio del Interior','Autoridades, comunidades, resguardos, asociaciones, Kumpany y organizaciones Rrom','https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/','Verificar representación y autoridad antes de clasificar o trasladar un caso étnico.'),
('mininterior_narp','Registros y gestión de comunidades NARP','Ministerio del Interior','Consejos comunitarios y organizaciones NARP','https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/','Verificar representación, consejo comunitario y organización vinculada.'),
('mininterior_consulta_previa','Autoridad Nacional de Consulta Previa','Ministerio del Interior','Sujetos y procesos de consulta previa','https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/','Identificar cuándo el control debe advertir una salvaguarda de consulta previa.'),
('ant_territorios_etnicos','Información de tierras y territorios étnicos','Agencia Nacional de Tierras','Resguardos, territorios indígenas y tierras colectivas','https://www.ant.gov.co/glosario','Contrastar naturaleza y situación territorial antes de publicar clasificación definitiva.'),
('secop','SECOP','Colombia Compra Eficiente','Contratación pública','https://www.colombiacompra.gov.co/secop','Fuente primaria prioritaria para verificar procesos y contratos estatales.')
on conflict(code) do update set name=excluded.name,responsible_authority=excluded.responsible_authority,coverage=excluded.coverage,url=excluded.url,use_in_observatory=excluded.use_in_observatory,active=true,updated_at=now();

alter table public.findings add column if not exists scope_type_code text references public.control_scope_type_catalog(code);
alter table public.findings add column if not exists scope_name text;
alter table public.findings add column if not exists entity_type_code text references public.control_entity_type_catalog(code);
alter table public.findings add column if not exists subject_matter text;
alter table public.findings add column if not exists impact_level text check (impact_level is null or impact_level in ('bajo','medio','alto','critico'));
alter table public.findings add column if not exists control_route_code text references public.control_route_catalog(code);

alter table public.reports add column if not exists scope_type_code text references public.control_scope_type_catalog(code);
alter table public.reports add column if not exists scope_name text;
alter table public.reports add column if not exists entity_type_code text references public.control_entity_type_catalog(code);
alter table public.reports add column if not exists subject_matter text;
alter table public.reports add column if not exists impact_level text check (impact_level is null or impact_level in ('bajo','medio','alto','critico'));
alter table public.reports add column if not exists control_route_code text references public.control_route_catalog(code);

alter table public.territorial_roles add column if not exists scope_type_code text references public.control_scope_type_catalog(code);
alter table public.territorial_roles add column if not exists scope_name text;

create index if not exists findings_detailed_scope_idx on public.findings(scope_type_code,scope_name);
create index if not exists findings_entity_type_idx on public.findings(entity_type_code);
create index if not exists reports_detailed_scope_idx on public.reports(scope_type_code,scope_name);
create index if not exists reports_entity_type_idx on public.reports(entity_type_code);
create index if not exists territorial_roles_scope_type_idx on public.territorial_roles(scope_type_code,scope_name);

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
  v_entity_type text := nullif(p_report->>'entidadTipo','');
begin
  if v_level not in ('nacional','departamental','distrital','municipal','regional') then raise exception 'Nivel de vigilancia inválido'; end if;
  if v_scope is not null and not exists(select 1 from public.control_scope_type_catalog where code=v_scope and active=true) then raise exception 'Ámbito de control inválido'; end if;
  if v_entity_type is not null and not exists(select 1 from public.control_entity_type_catalog where code=v_entity_type and active=true) then raise exception 'Tipo de entidad inválido'; end if;
  if length(trim(coalesce(p_report->>'entidad',''))) < 2 then raise exception 'Entidad requerida'; end if;
  if length(trim(coalesce(p_report->>'actoId',''))) < 2 then raise exception 'Identificación del acto requerida'; end if;
  if length(trim(coalesce(p_report->>'hecho',''))) < 40 then raise exception 'Relato demasiado corto'; end if;

  insert into public.reports(
    id,level,region,department,municipality,territory,scope_type_code,scope_name,entity_type_code,subject_matter,impact_level,control_route_code,
    entity_name,act_type,act_id,act_date,class_hint,payload
  ) values (
    v_id,v_level,nullif(p_report->>'region',''),nullif(p_report->>'departamento',''),nullif(p_report->>'municipio',''),nullif(p_report->>'territorio',''),
    v_scope,nullif(p_report->>'ambitoNombre',''),v_entity_type,nullif(p_report->>'materia',''),nullif(p_report->>'impacto',''),nullif(p_report->>'rutaControl',''),
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
declare r public.reports%rowtype; v_finding_id uuid;
begin
  select * into r from public.reports where id=p_report_id for update;
  if not found then raise exception 'Reporte no encontrado'; end if;
  if not public.can_curate_scope(r.level,r.region,r.department,r.municipality) then raise exception 'Sin competencia de curaduría para este territorio'; end if;
  if p_outcome='promoted' then
    if p_finding is null then raise exception 'Ficha requerida'; end if;
    v_finding_id:=gen_random_uuid();
    insert into public.findings(
      id,level,region,department,municipality,territory,scope_type_code,scope_name,entity_type_code,subject_matter,impact_level,control_route_code,
      entity_name,act_type,act_id,act_date,finding_class,verification_status,replica_status,published,payload,created_by,updated_by
    ) values (
      v_finding_id,coalesce(p_finding->>'nivel',r.level),coalesce(nullif(p_finding->>'region',''),r.region),coalesce(nullif(p_finding->>'departamento',''),r.department),
      coalesce(nullif(p_finding->>'municipio',''),r.municipality),coalesce(nullif(p_finding->>'territorio',''),r.territory),
      coalesce(nullif(p_finding->>'ambitoTipo',''),r.scope_type_code),coalesce(nullif(p_finding->>'ambitoNombre',''),r.scope_name),coalesce(nullif(p_finding->>'entidadTipo',''),r.entity_type_code),
      coalesce(nullif(p_finding->>'materia',''),r.subject_matter),coalesce(nullif(p_finding->>'impacto',''),r.impact_level),coalesce(nullif(p_finding->>'rutaControl',''),r.control_route_code),
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

create or replace function public.enforce_finding_publication_quality()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.published=true then
    if new.verification_status <> 'documentado' then raise exception 'Publicación bloqueada: la ficha debe estar DOCUMENTADA'; end if;
    if new.replica_status not in ('respondido','no_aplica') then raise exception 'Publicación bloqueada: la réplica debe estar respondida o motivadamente marcada como no aplicable'; end if;
    if not exists(select 1 from public.sources s where s.finding_id=new.id and s.is_primary=true and s.verified=true) then
      raise exception 'Publicación bloqueada: falta una fuente primaria verificada';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.enforce_finding_publication_quality() from public,anon,authenticated;
drop trigger if exists findings_publication_quality on public.findings;
create trigger findings_publication_quality before insert or update of published,verification_status,replica_status on public.findings for each row execute function public.enforce_finding_publication_quality();

create or replace view public.public_control_scope_catalog with (security_invoker=true) as
select code,name,family,is_ethnic_territorial,is_special_control_scope,control_notes,normative_basis,official_reference_url,sort_order
from public.control_scope_type_catalog where active=true;
create or replace view public.public_control_entity_catalog with (security_invoker=true) as
select code,name,family,branch_or_system,governance_level,is_state_entity,is_collective_governance,control_focus,normative_basis,official_reference_url,notes,sort_order
from public.control_entity_type_catalog where active=true;
create or replace view public.public_control_route_catalog with (security_invoker=true) as
select code,name,family,when_to_use,authority_hint,normative_basis,notes,sort_order from public.control_route_catalog where active=true;
create or replace view public.public_control_reference_registries with (security_invoker=true) as
select code,name,responsible_authority,coverage,url,use_in_observatory from public.control_reference_registries where active=true;

grant select on public.public_control_scope_catalog,public.public_control_entity_catalog,public.public_control_route_catalog,public.public_control_reference_registries to anon,authenticated;
