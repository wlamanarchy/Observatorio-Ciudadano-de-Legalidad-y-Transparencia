-- CONSENSO — catálogo público de entidades, autoridades y ámbitos de participación.
-- Objetivo: evitar que la plataforma reduzca la participación a la estructura administrativa clásica.
-- Distingue entre: entidades/órganos públicos, autoridades colectivas, instancias de participación y ámbitos territoriales.
-- Fuentes normativas de referencia: Constitución Política; Manual de Estructura del Estado (Función Pública);
-- Ley 70 de 1993; Decreto 1088 de 1993; Decreto 1953 de 2014; Decreto 2957 de 2010; Ley 1454 de 2011;
-- Ley 1625 de 2013; Ley 1757 de 2015; Ley 1962 de 2019; Ley 2166 de 2021 y demás normas aplicables.

create table if not exists public.entity_type_catalog(
  code text primary key,
  name text not null,
  family text not null,
  branch_or_system text not null,
  governance_level text,
  role_kind text not null,
  is_state_entity boolean not null default true,
  is_collective_governance boolean not null default false,
  competence_summary text not null,
  typical_instruments text[] not null default '{}',
  normative_basis text[] not null default '{}',
  official_reference_url text,
  notes text,
  sort_order integer not null default 1000,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.entity_type_catalog enable row level security;
drop policy if exists entity_type_catalog_public_read on public.entity_type_catalog;
create policy entity_type_catalog_public_read on public.entity_type_catalog
for select using(active=true);
revoke insert,update,delete on public.entity_type_catalog from anon,authenticated;
grant select on public.entity_type_catalog to anon,authenticated;

create table if not exists public.scope_type_catalog(
  code text primary key,
  name text not null,
  family text not null,
  level_order integer not null,
  is_ethnic_territorial boolean not null default false,
  is_special_planning_scope boolean not null default false,
  governance_notes text not null,
  typical_instruments text[] not null default '{}',
  normative_basis text[] not null default '{}',
  official_reference_url text,
  active boolean not null default true,
  sort_order integer not null default 1000,
  updated_at timestamptz not null default now()
);

alter table public.scope_type_catalog enable row level security;
drop policy if exists scope_type_catalog_public_read on public.scope_type_catalog;
create policy scope_type_catalog_public_read on public.scope_type_catalog
for select using(active=true);
revoke insert,update,delete on public.scope_type_catalog from anon,authenticated;
grant select on public.scope_type_catalog to anon,authenticated;

create table if not exists public.reference_registries(
  code text primary key,
  name text not null,
  responsible_authority text not null,
  coverage text not null,
  url text not null,
  use_in_consenso text not null,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.reference_registries enable row level security;
drop policy if exists reference_registries_public_read on public.reference_registries;
create policy reference_registries_public_read on public.reference_registries
for select using(active=true);
revoke insert,update,delete on public.reference_registries from anon,authenticated;
grant select on public.reference_registries to anon,authenticated;

create table if not exists public.participation_scopes(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  scope_type_code text not null references public.scope_type_catalog(code),
  parent_scope_id uuid references public.participation_scopes(id),
  region text,
  department text,
  municipality text,
  official_code text,
  governing_authority_name text,
  own_instrument text,
  official_source_url text,
  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists participation_scopes_type_idx on public.participation_scopes(scope_type_code,active);
create index if not exists participation_scopes_parent_idx on public.participation_scopes(parent_scope_id);
create index if not exists participation_scopes_territory_idx on public.participation_scopes(department,municipality);

alter table public.participation_scopes enable row level security;
drop policy if exists participation_scopes_public_read on public.participation_scopes;
create policy participation_scopes_public_read on public.participation_scopes
for select using(active=true);
revoke insert,update,delete on public.participation_scopes from anon,authenticated;
grant select on public.participation_scopes to anon,authenticated;

alter table public.institutions add column if not exists catalog_code text references public.entity_type_catalog(code);
alter table public.institutions add column if not exists legal_nature text;
alter table public.institutions add column if not exists branch_or_system text;
alter table public.institutions add column if not exists competence_summary text;
alter table public.institutions add column if not exists participation_instrument text;
alter table public.institutions add column if not exists normative_basis text[] not null default '{}';
alter table public.institutions add column if not exists governance_notes text;
alter table public.institutions add column if not exists official_registry_url text;
alter table public.institutions add column if not exists scope_id uuid references public.participation_scopes(id);
create index if not exists institutions_catalog_idx on public.institutions(catalog_code);
create index if not exists institutions_scope_idx on public.institutions(scope_id);

alter table public.participation_processes add column if not exists scope_id uuid references public.participation_scopes(id);
alter table public.proposals add column if not exists scope_id uuid references public.participation_scopes(id);
create index if not exists participation_processes_scope_idx on public.participation_processes(scope_id);
create index if not exists proposals_scope_id_idx on public.proposals(scope_id);

-- Catálogo de entidades, órganos, autoridades y actores institucionales.
insert into public.entity_type_catalog(
  code,name,family,branch_or_system,governance_level,role_kind,is_state_entity,is_collective_governance,
  competence_summary,typical_instruments,normative_basis,official_reference_url,notes,sort_order
) values
('presidencia_republica','Presidencia de la República','Administración nacional','Rama Ejecutiva','Nacional','entidad_publica',true,false,'Dirección general del Gobierno y coordinación superior de la administración nacional.',array['Plan Nacional de Desarrollo','planes estratégicos sectoriales','decretos y directivas'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,10),
('ministerio','Ministerio','Administración nacional','Rama Ejecutiva','Nacional','entidad_publica',true,false,'Formula y dirige políticas del sector administrativo a su cargo.',array['política sectorial','plan estratégico sectorial','proyectos normativos','plan de acción'],array['Ley 489 de 1998'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,20),
('departamento_administrativo','Departamento administrativo','Administración nacional','Rama Ejecutiva','Nacional','entidad_publica',true,false,'Formula o coordina políticas y funciones administrativas especializadas.',array['plan estratégico institucional','documentos de política','regulación cuando corresponda'],array['Ley 489 de 1998'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,30),
('superintendencia','Superintendencia','Administración nacional','Rama Ejecutiva','Nacional','entidad_publica',true,false,'Ejerce inspección, vigilancia y control en el sector que determine la ley.',array['planes de supervisión','circulares','resoluciones','proyectos regulatorios'],array['Ley 489 de 1998'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,40),
('unidad_administrativa_especial','Unidad administrativa especial','Administración nacional','Rama Ejecutiva','Nacional','entidad_publica',true,false,'Desarrolla funciones administrativas o técnicas especializadas, con o sin personería jurídica según su régimen.',array['plan estratégico institucional','resoluciones','programas sectoriales'],array['Ley 489 de 1998'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','Registrar la naturaleza particular de cada UAE.',50),
('agencia_estatal','Agencia estatal / agencia de naturaleza especial','Administración nacional','Rama Ejecutiva','Nacional','entidad_publica',true,false,'Ejecuta políticas, programas o funciones especializadas conforme a su norma de creación.',array['plan estratégico','programas','proyectos de inversión'],array['Norma de creación de cada agencia'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,60),
('establecimiento_publico','Establecimiento público','Descentralizado','Rama Ejecutiva','Nacional o territorial','entidad_publica',true,false,'Atiende funciones administrativas y presta servicios públicos conforme a su objeto legal.',array['plan institucional','plan de acción','proyectos de inversión'],array['Ley 489 de 1998'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,70),
('eice','Empresa industrial y comercial del Estado','Descentralizado','Rama Ejecutiva','Nacional o territorial','entidad_publica',true,false,'Desarrolla actividades industriales, comerciales o de gestión económica estatal.',array['plan empresarial','plan de inversiones','gobierno corporativo'],array['Ley 489 de 1998'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,80),
('sociedad_economia_mixta','Sociedad de economía mixta','Descentralizado','Rama Ejecutiva','Nacional o territorial','entidad_publica',true,false,'Desarrolla actividades económicas con participación pública y privada según su régimen societario y legal.',array['plan empresarial','plan de inversiones','gobierno corporativo'],array['Ley 489 de 1998','Código de Comercio'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','La aplicabilidad de reglas públicas depende de su composición y régimen concreto.',90),
('ese','Empresa Social del Estado','Descentralizado','Rama Ejecutiva','Nacional o territorial','entidad_publica',true,false,'Presta servicios de salud y adopta instrumentos de gestión institucional.',array['plan de gestión','plan de desarrollo institucional','portafolio de servicios'],array['Ley 100 de 1993'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,100),
('esp_oficial_mixta','Empresa de servicios públicos oficial o mixta','Descentralizado','Rama Ejecutiva','Nacional o territorial','entidad_publica',true,false,'Presta servicios públicos domiciliarios y ejecuta planes de obras e inversiones.',array['plan de obras e inversiones','plan empresarial','contrato de condiciones uniformes'],array['Ley 142 de 1994'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,110),
('congreso','Congreso de la República','Corporación pública','Rama Legislativa','Nacional','organo_publico',true,false,'Expide leyes, reforma la Constitución, ejerce control político y aprueba instrumentos nacionales de planeación y presupuesto.',array['proyecto de ley','acto legislativo','ley del plan','ley anual de presupuesto'],array['Constitución Política','Ley 5 de 1992'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,200),
('asamblea_departamental','Asamblea departamental','Corporación pública','Rama Legislativa','Departamental','organo_publico',true,false,'Expide ordenanzas y adopta decisiones departamentales dentro de sus competencias.',array['ordenanza','plan de desarrollo departamental','presupuesto departamental'],array['Constitución Política','régimen departamental vigente'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,210),
('concejo_municipal_distrital','Concejo municipal o distrital','Corporación pública','Rama Legislativa','Municipal o distrital','organo_publico',true,false,'Expide acuerdos y adopta planes, presupuestos y normas territoriales dentro de su competencia.',array['acuerdo municipal o distrital','plan de desarrollo','POT/PBOT/EOT','presupuesto'],array['Constitución Política','Ley 136 de 1994','Ley 1757 de 2015'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,220),
('junta_administradora_local','Junta Administradora Local','Corporación pública','Rama Legislativa','Local','organo_publico',true,false,'Participa en asuntos de localidades, comunas o corregimientos y en priorización local conforme al régimen aplicable.',array['acuerdos o resoluciones locales','planes de desarrollo local','priorización de inversiones'],array['Constitución Política','Ley 136 de 1994','Ley 1757 de 2015'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,230),
('altas_cortes','Altas Cortes','Administración de justicia','Rama Judicial','Nacional','organo_publico',true,false,'Ejercen las competencias constitucionales y legales propias de cada jurisdicción.',array['planes institucionales cuando correspondan','reglamentos internos'],array['Constitución Política','Ley 270 de 1996'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','La plataforma no somete decisiones judiciales a votación ciudadana; solo puede abrir participación sobre planeación y gestión cuando jurídicamente proceda.',300),
('consejo_superior_judicatura','Consejo Superior de la Judicatura','Administración de justicia','Rama Judicial','Nacional','organo_publico',true,false,'Administra y gobierna la Rama Judicial en las materias de su competencia.',array['plan sectorial de desarrollo','planes de inversión y gestión judicial'],array['Constitución Política','Ley 270 de 1996'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,310),
('fiscalia_general','Fiscalía General de la Nación','Administración de justicia','Rama Judicial','Nacional','entidad_publica',true,false,'Investiga y acusa conductas punibles conforme a la Constitución y la ley y administra su organización institucional.',array['plan estratégico institucional','política criminal en el ámbito de sus competencias'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','La participación no puede interferir investigaciones ni decisiones reservadas.',320),
('jep','Jurisdicción Especial para la Paz','Sistema Integral de Paz','Sistema Integral de Verdad, Justicia, Reparación y No Repetición','Nacional','organo_publico',true,false,'Administra justicia transicional dentro de su competencia y desarrolla su planeación institucional.',array['plan estratégico','instrumentos de participación de víctimas cuando procedan'],array['Acto Legislativo 01 de 2017'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,330),
('procuraduria','Procuraduría General de la Nación','Control','Organismos de Control','Nacional','organo_publico',true,false,'Ejerce funciones preventivas, disciplinarias y de intervención conforme al ordenamiento.',array['plan estratégico','directivas preventivas','programas de vigilancia'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,400),
('defensoria','Defensoría del Pueblo','Control','Organismos de Control','Nacional','organo_publico',true,false,'Promueve, ejerce y divulga los derechos humanos y orienta a la ciudadanía.',array['plan estratégico','informes defensoriales','alertas tempranas'],array['Constitución Política','Ley 24 de 1992'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,410),
('contraloria_general','Contraloría General de la República','Control fiscal','Organismos de Control','Nacional','organo_publico',true,false,'Vigila y controla la gestión fiscal de los recursos públicos dentro de su competencia.',array['plan de vigilancia y control fiscal','auditorías y actuaciones fiscales'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,420),
('auditoria_general','Auditoría General de la República','Control fiscal','Organismos de Control','Nacional','organo_publico',true,false,'Vigila la gestión fiscal de las contralorías en los términos del ordenamiento.',array['plan de vigilancia fiscal','auditorías'],array['Constitución Política','normas orgánicas aplicables'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,430),
('contraloria_territorial','Contraloría territorial','Control fiscal','Organismos de Control','Territorial','organo_publico',true,false,'Ejerce control fiscal territorial en el ámbito que la ley determine.',array['plan territorial de vigilancia y control fiscal'],array['Constitución Política','régimen de control fiscal vigente'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,440),
('personeria','Personería municipal o distrital','Ministerio Público territorial','Organismos de Control','Municipal o distrital','organo_publico',true,false,'Ejerce funciones de Ministerio Público en el territorio y acompaña derechos, control social y veedurías.',array['plan institucional','actuaciones preventivas y de defensa de derechos'],array['Ley 136 de 1994','Ley 850 de 2003'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,450),
('consejo_nacional_electoral','Consejo Nacional Electoral','Organización electoral','Organización Electoral','Nacional','organo_publico',true,false,'Ejerce las funciones constitucionales y legales de inspección, vigilancia y regulación electoral.',array['resoluciones','planes institucionales'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,500),
('registraduria','Registraduría Nacional del Estado Civil','Organización electoral','Organización Electoral','Nacional','entidad_publica',true,false,'Organiza procesos electorales y de participación formal y administra la identificación civil en el marco de sus competencias.',array['planes electorales','plan estratégico institucional','procedimientos de mecanismos de participación'],array['Constitución Política','Ley 1757 de 2015'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,510),
('banco_republica','Banco de la República','Autónomo','Órganos Autónomos e Independientes','Nacional','organo_autonomo',true,false,'Ejerce funciones de banca central con autonomía constitucional.',array['informes de política','regulación de su competencia','plan estratégico institucional'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,600),
('cnsc','Comisión Nacional del Servicio Civil','Autónomo','Órganos Autónomos e Independientes','Nacional','organo_autonomo',true,false,'Administra y vigila los sistemas de carrera administrativa dentro de su competencia.',array['acuerdos','planes institucionales','convocatorias'],array['Constitución Política'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,610),
('car_cds','Corporación Autónoma Regional o de Desarrollo Sostenible','Ambiental','Órganos Autónomos e Independientes','Regional','organo_autonomo',true,false,'Ejerce autoridad ambiental regional y adopta instrumentos de planificación y gestión ambiental.',array['PGAR','plan de acción institucional','POMCA','actos ambientales'],array['Ley 99 de 1993'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estado/organos-autonomos.php',null,620),
('universidad_publica','Universidad estatal u oficial / ente universitario autónomo','Educación superior','Órganos Autónomos e Independientes','Nacional o territorial','organo_autonomo',true,false,'Ejerce autonomía universitaria y define sus instrumentos de gobierno, desarrollo, docencia, investigación, extensión y regionalización.',array['plan de desarrollo institucional','estatuto general','plan académico','plan de regionalización'],array['Constitución Política','Ley 30 de 1992'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','La competencia concreta depende de sus órganos de gobierno y estatutos.',630),
('gobernacion','Gobernación departamental','Gobierno territorial','Rama Ejecutiva','Departamental','entidad_publica',true,false,'Dirige la administración departamental y formula y ejecuta los instrumentos territoriales de su competencia.',array['plan de desarrollo departamental','POAI','plan de ordenamiento departamental cuando proceda'],array['Constitución Política','Ley 152 de 1994'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,700),
('alcaldia','Alcaldía municipal o distrital','Gobierno territorial','Rama Ejecutiva','Municipal o distrital','entidad_publica',true,false,'Dirige la administración municipal o distrital y formula los instrumentos de desarrollo y ordenamiento territorial.',array['plan de desarrollo','POT/PBOT/EOT','POAI','presupuesto'],array['Constitución Política','Ley 136 de 1994','Ley 152 de 1994'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',null,710),
('area_metropolitana','Área metropolitana','Esquema territorial','Régimen territorial','Supramunicipal','entidad_publica',true,false,'Coordina hechos metropolitanos y funciones atribuidas por su régimen legal.',array['plan integral de desarrollo metropolitano','planes y programas metropolitanos'],array['Ley 1625 de 2013'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=52972',null,720),
('rap','Región Administrativa y de Planificación','Esquema territorial','Régimen territorial','Regional','entidad_publica',true,false,'Articula planeación y proyectos de alcance regional entre entidades territoriales.',array['plan estratégico regional','proyectos de impacto regional'],array['Ley 1454 de 2011','Ley 1962 de 2019'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',null,730),
('provincia_administrativa_planificacion','Provincia administrativa y de planificación','Esquema territorial','Régimen territorial','Supramunicipal','entidad_publica',true,false,'Articula municipios para planificación, gestión y proyectos comunes conforme al ordenamiento territorial.',array['plan o agenda provincial','proyectos supramunicipales'],array['Ley 1454 de 2011'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',null,740),
('asociacion_entidades_territoriales','Asociación de entidades territoriales','Esquema territorial','Régimen territorial','Supraterritorial','entidad_publica',true,false,'Asocia entidades territoriales para prestar servicios, ejecutar obras o desarrollar funciones administrativas comunes.',array['convenio asociativo','plan de acción conjunto','proyectos regionales'],array['Ley 1454 de 2011'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',null,750),
('ocad_sgr','Órgano Colegiado de Administración y Decisión del SGR','Regalías','Sistema General de Regalías','Regional o sectorial','organo_colegiado',true,false,'Ejerce funciones de priorización, viabilización o aprobación de proyectos de regalías según el régimen vigente y el tipo de OCAD.',array['acuerdos OCAD','planes de convocatorias o inversiones cuando proceda'],array['Ley 2056 de 2020'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=142858','Registrar el OCAD concreto y su competencia vigente.',760),
('consejo_nacional_planeacion','Consejo Nacional de Planeación','Planeación participativa','Instancia de Participación','Nacional','instancia_participacion',false,false,'Emite concepto y organiza participación de sectores y territorios en la planeación nacional.',array['concepto al Plan Nacional de Desarrollo','recomendaciones de planeación'],array['Constitución Política','Ley 152 de 1994'], 'https://www.dnp.gov.co/LaEntidad_/subdireccion-general-prospectiva-desarrollo-nacional/direccion-gobierno-ddhh-paz/Paginas/planeaci%C3%B3n-participativa.aspx',null,800),
('consejo_territorial_planeacion','Consejo Territorial de Planeación','Planeación participativa','Instancia de Participación','Territorial','instancia_participacion',false,false,'Representa sectores y grupos de la sociedad civil en la discusión de planes territoriales de desarrollo.',array['concepto al plan de desarrollo territorial','recomendaciones'],array['Constitución Política','Ley 152 de 1994'], 'https://www.dnp.gov.co/LaEntidad_/subdireccion-general-prospectiva-desarrollo-nacional/direccion-gobierno-ddhh-paz/Paginas/planeaci%C3%B3n-participativa.aspx',null,810),
('organismo_accion_comunal','Organismo de acción comunal','Organización ciudadana','Instancia de Participación','Local','actor_participacion',false,true,'Organiza participación comunitaria y gestión colectiva en barrios, veredas y demás ámbitos reconocidos por la ley comunal.',array['plan de desarrollo comunal y comunitario','acuerdos y proyectos comunitarios'],array['Ley 2166 de 2021'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=184758',null,820),
('veeduria_ciudadana','Veeduría ciudadana','Control social','Instancia de Participación','Todos','actor_participacion',false,false,'Ejerce vigilancia ciudadana sobre la gestión pública conforme a su objeto y registro.',array['plan de vigilancia','informes y observaciones de control social'],array['Ley 850 de 2003','Ley 1757 de 2015'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=10570',null,830),
('resguardo_indigena','Resguardo indígena','Gobierno y territorio indígena','Gobierno propio / autonomía étnica','Étnico-territorial','institucion_sociopolitica',false,true,'Institución legal y sociopolítica de carácter especial, con propiedad colectiva y organización autónoma para el manejo del territorio y la vida interna.',array['plan de vida','reglamento o derecho propio','presupuesto de asignación especial del SGP cuando corresponda'],array['Constitución Política arts. 63 y 329','Decreto 2164 de 1995','Decreto 1953 de 2014'], 'https://www.ant.gov.co/glosario','El resguardo es también un ámbito territorial. La autoridad competente debe registrarse separadamente: cabildo, autoridad tradicional, consejo indígena u otra estructura propia.',900),
('territorio_indigena_1953','Territorio indígena en funcionamiento','Gobierno y territorio indígena','Gobierno propio / autonomía étnica','Étnico-territorial','organizacion_politico_administrativa_especial',false,true,'Organización político-administrativa especial que puede ejercer funciones públicas y administrar sistemas propios conforme al Decreto 1953 de 2014.',array['plan de vida','instrumentos propios de educación, salud, agua y demás sistemas asumidos','presupuesto propio'],array['Decreto 1953 de 2014'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=59636','No debe confundirse automáticamente con una entidad territorial indígena plenamente desarrollada por ley orgánica.',910),
('cabildo_indigena','Cabildo indígena','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial','autoridad_colectiva',false,true,'Forma de autoridad y gobierno de comunidades o resguardos indígenas, de acuerdo con sus normas propias y el marco jurídico aplicable.',array['plan de vida','actas y decisiones de gobierno propio','instrumentos comunitarios'],array['Ley 89 de 1890','Decreto 1088 de 1993','Decreto 1953 de 2014'], 'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,920),
('autoridad_tradicional_indigena','Autoridad tradicional indígena','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial','autoridad_colectiva',false,true,'Autoridad propia reconocida por la comunidad de acuerdo con sus usos, derecho propio y régimen aplicable.',array['decisiones de gobierno propio','plan de vida','mandatos comunitarios'],array['Convenio 169 OIT - Ley 21 de 1991','Decreto 1088 de 1993','Decreto 1953 de 2014'], 'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,930),
('consejo_indigena_gobierno_propio','Consejo indígena o estructura colectiva similar de gobierno propio','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial','autoridad_colectiva',false,true,'Estructura colectiva de gobierno propio habilitada para ejercer competencias de los territorios indígenas cuando corresponda.',array['plan de vida','presupuesto y actos de gobierno propio','instrumentos de sistemas propios'],array['Decreto 1953 de 2014'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=59636',null,940),
('asociacion_cabildos_autoridades','Asociación de cabildos y/o autoridades tradicionales indígenas','Asociación indígena','Gobierno propio / autonomía étnica','Supraterritorial indígena','entidad_derecho_publico_especial',false,true,'Entidad de derecho público de carácter especial constituida por cabildos y/o autoridades tradicionales para el desarrollo integral de sus comunidades.',array['estatutos','plan o agenda de la asociación','proyectos comunitarios'],array['Decreto 1088 de 1993'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=1501',null,950),
('asociacion_resguardos_indigenas','Asociación de resguardos indígenas','Asociación indígena','Gobierno propio / autonomía étnica','Supraterritorial indígena','autoridad_colectiva',false,true,'Forma asociativa registrada para coordinación y representación de resguardos conforme al régimen aplicable.',array['estatutos','agenda o plan asociativo'],array['Decreto 1953 de 2014 y normas aplicables'], 'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/','Validar en el registro oficial el alcance jurídico concreto de cada asociación.',960),
('consejo_territorial_indigena','Consejo Territorial Indígena','Gobierno indígena','Gobierno propio / autonomía étnica','Étnico-territorial','autoridad_colectiva',false,true,'Instancia de gobierno/administración indígena registrada conforme al régimen especial aplicable.',array['instrumentos propios de gobierno y planeación'],array['Régimen especial aplicable'], 'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/','Usar únicamente cuando exista registro oficial y competencia verificable.',970),
('consejo_comunitario_narp','Consejo comunitario de comunidades negras, afrocolombianas, raizales y palenqueras','Gobierno colectivo NARP','Autonomía étnica y territorio colectivo','Étnico-territorial','autoridad_colectiva',false,true,'Forma de administración interna y representación de la comunidad sobre su territorio colectivo y sus asuntos comunitarios conforme al régimen aplicable.',array['reglamento interno','plan de etnodesarrollo','plan de manejo o instrumentos comunitarios'],array['Ley 70 de 1993','Decreto 1745 de 1995','Convenio 169 OIT - Ley 21 de 1991'], 'https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/',null,980),
('tierra_colectiva_narp','Tierra o territorio colectivo de comunidades negras, afrocolombianas, raizales y palenqueras','Territorio colectivo NARP','Autonomía étnica y territorio colectivo','Étnico-territorial','ambito_juridico',false,true,'Ámbito territorial colectivo reconocido o en trámite conforme al régimen de comunidades negras y al proceso de titulación aplicable.',array['plan de etnodesarrollo','reglamento interno del consejo comunitario','instrumentos de ordenamiento y manejo'],array['Ley 70 de 1993','Decreto 1745 de 1995'], 'https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/','La autoridad representativa se registra separadamente del territorio.',990),
('organizacion_narp','Organización o forma/expresión organizativa NARP','Organización étnica','Participación étnica','Local, territorial o nacional','actor_participacion',false,true,'Organiza y representa intereses colectivos de comunidades negras, afrocolombianas, raizales y palenqueras según su naturaleza y registro.',array['estatutos','agenda organizativa','proyectos y propuestas colectivas'],array['Ley 70 de 1993','Decreto 1066 de 2015','Decreto 1640 de 2020'], 'https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/',null,1000),
('organizacion_segundo_nivel_narp','Organización de segundo nivel NARP','Organización étnica','Participación étnica','Supraterritorial','actor_participacion',false,true,'Articula consejos comunitarios u organizaciones NARP conforme al régimen de registro aplicable.',array['estatutos','agenda organizativa','planes y proyectos colectivos'],array['Decreto 1066 de 2015','Decreto 1640 de 2020'], 'https://www.mininterior.gov.co/organizaciones-elegibles/',null,1010),
('kumpania_rom','Kumpania del pueblo Rrom','Gobierno y organización Rrom','Autonomía étnica Rrom','Étnico-comunitario','institucion_sociopolitica',false,true,'Conjunto de grupos familiares Rrom que comparten espacios de vida o itinerancia y constituye una institución político-social propia.',array['acuerdos propios','agenda o plan de la Kumpania','procesos de consulta previa cuando proceda'],array['Decreto 2957 de 2010'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=40124',null,1020),
('organizacion_rom','Organización Rrom registrada','Organización étnica','Autonomía étnica Rrom','Local o nacional','actor_participacion',false,true,'Organización del pueblo Rrom reconocida en los registros y procedimientos del Ministerio del Interior.',array['estatutos','agenda organizativa','procesos de diálogo y consulta'],array['Decreto 2957 de 2010'], 'https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/',null,1030)
on conflict(code) do update set
  name=excluded.name,family=excluded.family,branch_or_system=excluded.branch_or_system,governance_level=excluded.governance_level,
  role_kind=excluded.role_kind,is_state_entity=excluded.is_state_entity,is_collective_governance=excluded.is_collective_governance,
  competence_summary=excluded.competence_summary,typical_instruments=excluded.typical_instruments,normative_basis=excluded.normative_basis,
  official_reference_url=excluded.official_reference_url,notes=excluded.notes,sort_order=excluded.sort_order,active=true,updated_at=now();

-- Catálogo de ámbitos donde puede abrirse un proceso participativo.
insert into public.scope_type_catalog(
  code,name,family,level_order,is_ethnic_territorial,is_special_planning_scope,governance_notes,typical_instruments,normative_basis,official_reference_url,sort_order
) values
('nacional','Colombia / ámbito nacional','Territorial',10,false,false,'Ámbito nacional para procesos de visión país, políticas, normas y planes nacionales.',array['Plan Nacional de Desarrollo','políticas nacionales','leyes y regulación nacional'],array['Constitución Política','Ley 152 de 1994'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',10),
('regional','Región / ámbito supradepartamental','Territorial',20,false,true,'Ámbito para problemas, estrategias y proyectos que exceden un departamento.',array['planes y agendas regionales'],array['Ley 1454 de 2011','Ley 1962 de 2019'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',20),
('rap','Región Administrativa y de Planificación','Esquema asociativo territorial',21,false,true,'Ámbito de una RAP constituida y de su planeación estratégica regional.',array['plan estratégico regional'],array['Ley 1454 de 2011','Ley 1962 de 2019'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',21),
('departamental','Departamento','Territorial',30,false,false,'Ámbito departamental.',array['Plan de Desarrollo Departamental','instrumentos departamentales'],array['Constitución Política','Ley 152 de 1994'], 'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',30),
('distrital','Distrito','Territorial',40,false,false,'Ámbito distrital conforme al régimen especial correspondiente.',array['Plan de Desarrollo Distrital','POT','presupuesto distrital'],array['Constitución Política','Ley 152 de 1994'], 'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',40),
('municipal','Municipio','Territorial',50,false,false,'Ámbito municipal.',array['Plan de Desarrollo Municipal','POT/PBOT/EOT','presupuesto municipal'],array['Constitución Política','Ley 136 de 1994','Ley 152 de 1994'], 'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',50),
('localidad','Localidad','Local',60,false,false,'Subdivisión político-administrativa local donde exista legalmente.',array['plan de desarrollo local','presupuesto local'],array['Régimen distrital o municipal aplicable'], 'https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola',60),
('comuna','Comuna','Local',61,false,false,'Ámbito urbano submunicipal para participación y planeación local cuando corresponda.',array['planes de desarrollo local/comunal','presupuesto participativo'],array['Ley 136 de 1994','Ley 1757 de 2015'], null,61),
('corregimiento','Corregimiento','Local',62,false,false,'Ámbito rural o especial submunicipal reconocido por el régimen territorial aplicable.',array['planes o agendas locales','presupuesto participativo'],array['Ley 136 de 1994','Ley 1757 de 2015'], null,62),
('vereda','Vereda','Local',63,false,false,'Ámbito comunitario rural para diagnóstico y construcción participativa; no se presume entidad territorial.',array['planes comunitarios','proyectos rurales','PDET cuando corresponda'],array['Ley 1757 de 2015','Ley 2166 de 2021'], null,63),
('area_metropolitana','Área metropolitana','Esquema asociativo territorial',70,false,true,'Ámbito supramunicipal de hechos metropolitanos y planeación conjunta.',array['plan integral de desarrollo metropolitano'],array['Ley 1625 de 2013'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=52972',70),
('provincia_administrativa_planificacion','Provincia administrativa y de planificación','Esquema asociativo territorial',71,false,true,'Ámbito asociativo supramunicipal cuando esté constituido.',array['agenda o plan provincial'],array['Ley 1454 de 2011'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=43210',71),
('pdet_subregion','Subregión PDET','Planeación especial',72,false,true,'Ámbito de planeación participativa para municipios y comunidades de una subregión PDET.',array['PATR','hoja de ruta PDET','iniciativas PDET'],array['Decreto Ley 893 de 2017'], 'https://www.renovacionterritorio.gov.co/',72),
('zona_reserva_campesina','Zona de Reserva Campesina','Planeación rural especial',73,false,true,'Ámbito de ordenamiento social, ambiental y productivo rural con organización comunitaria.',array['plan de desarrollo sostenible de la ZRC'],array['Ley 160 de 1994','Decreto 1777 de 1996'], 'https://www.ant.gov.co/',73),
('cuenca_pomca','Cuenca o unidad hidrográfica de planificación','Planeación ambiental',74,false,true,'Ámbito ecosistémico para procesos ligados al ordenamiento y manejo de cuencas.',array['POMCA','planes de manejo y gestión ambiental'],array['Decreto 1076 de 2015'], 'https://www.minambiente.gov.co/',74),
('institucional','Institución pública o autónoma','Institucional',80,false,true,'Ámbito interno de una universidad, entidad, órgano autónomo u otra institución pública.',array['plan institucional','estatutos','plan estratégico','reglamentos','políticas internas'],array['Norma orgánica y estatutos de cada institución'], 'https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado',80),
('resguardo_indigena','Resguardo indígena','Étnico-territorial',90,true,true,'Institución legal y sociopolítica de carácter especial y territorio de propiedad colectiva. Debe identificarse también la autoridad propia que ejerce gobierno.',array['plan de vida','derecho propio','presupuesto de asignación especial del SGP cuando corresponda'],array['Constitución Política arts. 63 y 329','Decreto 2164 de 1995','Decreto 1953 de 2014'], 'https://www.ant.gov.co/glosario',90),
('territorio_indigena','Territorio indígena','Étnico-territorial',91,true,true,'Área de vida, posesión tradicional o territorio en funcionamiento conforme al régimen aplicable; puede ejercer funciones públicas a través de autoridades propias cuando se cumplen los presupuestos legales.',array['plan de vida','instrumentos de sistemas propios'],array['Decreto 1953 de 2014'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=59636',91),
('comunidad_parcialidad_indigena','Comunidad o parcialidad indígena','Étnico-territorial',92,true,true,'Unidad comunitaria indígena reconocida para efectos de participación, consulta y gobierno propio, aun cuando su situación territorial requiera identificación específica.',array['plan de vida','mandatos o instrumentos propios'],array['Convenio 169 OIT - Ley 21 de 1991','régimen indígena aplicable'], 'https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/',92),
('territorio_ancestral_indigena','Territorio ancestral o tradicional indígena','Étnico-territorial',93,true,true,'Ámbito tradicional de actividades sociales, económicas y culturales que debe ser identificado con fuente oficial y autoridad propia.',array['plan de vida','instrumentos de protección territorial'],array['Convenio 169 OIT - Ley 21 de 1991','régimen de protección territorial indígena'], 'https://apps.ant.gov.co/BARRIDO_PREDIAL/3-4-6-medidas-de-proteccion-y-seguridad-juridica-de-las-tierras-y-territorios-ocupados-o-poseidos-ancestralmente-yo-tradicionalmente-por-los-pueblos-indigenas/',93),
('tierra_colectiva_narp','Tierra o territorio colectivo NARP','Étnico-territorial',94,true,true,'Territorio colectivo de comunidades negras, afrocolombianas, raizales o palenqueras, titulado o en trámite según corresponda.',array['plan de etnodesarrollo','reglamento interno','instrumentos comunitarios de manejo'],array['Ley 70 de 1993','Decreto 1745 de 1995'], 'https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/',94),
('consejo_comunitario_territorio','Ámbito de un consejo comunitario NARP','Étnico-territorial',95,true,true,'Ámbito comunitario cuya representación y gobierno corresponden al consejo comunitario y sus órganos conforme al régimen aplicable.',array['plan de etnodesarrollo','reglamento interno'],array['Ley 70 de 1993','Decreto 1745 de 1995'], 'https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/',95),
('territorio_raizal','Territorio o comunidad raizal','Étnico-territorial',96,true,true,'Ámbito para procesos que afecten directamente a la comunidad raizal, respetando sus organizaciones y mecanismos representativos reconocidos.',array['planes y acuerdos comunitarios','consulta previa cuando proceda'],array['Constitución Política','Convenio 169 OIT - Ley 21 de 1991','normas especiales del Archipiélago'], 'https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/',96),
('territorio_palenquero','Territorio o comunidad palenquera','Étnico-territorial',97,true,true,'Ámbito para procesos propios de comunidades palenqueras y sus formas organizativas reconocidas.',array['planes y acuerdos comunitarios','consulta previa cuando proceda'],array['Ley 70 de 1993','Convenio 169 OIT - Ley 21 de 1991'], 'https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/',97),
('kumpania_rom','Kumpania del pueblo Rrom','Étnico-comunitario',98,true,true,'Ámbito político-social propio del pueblo Rrom, normalmente localizado en contextos urbanos pero diferenciado de la división administrativa ordinaria.',array['acuerdos propios','agenda comunitaria','consulta previa cuando proceda'],array['Decreto 2957 de 2010'], 'https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=40124',98)
on conflict(code) do update set
  name=excluded.name,family=excluded.family,level_order=excluded.level_order,is_ethnic_territorial=excluded.is_ethnic_territorial,
  is_special_planning_scope=excluded.is_special_planning_scope,governance_notes=excluded.governance_notes,
  typical_instruments=excluded.typical_instruments,normative_basis=excluded.normative_basis,
  official_reference_url=excluded.official_reference_url,sort_order=excluded.sort_order,active=true,updated_at=now();

insert into public.reference_registries(code,name,responsible_authority,coverage,url,use_in_consenso) values
('dafp_estructura_estado','Manual de Estructura del Estado Colombiano','Departamento Administrativo de la Función Pública','Ramas del poder, órganos autónomos e independientes, organización electoral, organismos de control y sistema integral','https://www.funcionpublica.gov.co/gestor-normativo/manual-estructura-del-estado','Fuente maestra para clasificar entidades y órganos públicos antes de abrir un proceso institucional.'),
('dane_divipola','DIVIPOLA','DANE','Departamentos, municipios, distritos y codificación territorial oficial','https://www.dane.gov.co/index.php/servicios-al-ciudadano/servicios-informacion/divipola','Fuente maestra para códigos y jerarquía territorial ordinaria.'),
('mininterior_indigenas_rom','Registros de autoridades indígenas, resguardos, asociaciones y pueblo Rrom','Ministerio del Interior','Autoridades/cabildos, comunidades y resguardos indígenas; asociaciones; Kumpany y organizaciones Rrom','https://www.mininterior.gov.co/direccion-de-asuntos-indigenas-rom-y-minorias/','Verificar existencia, autoridad y representación antes de dirigir acuerdos o habilitar ámbitos étnicos concretos.'),
('mininterior_narp','Registro y gestión de consejos comunitarios y organizaciones NARP','Ministerio del Interior','Consejos comunitarios, organizaciones, formas y expresiones organizativas NARP','https://www.mininterior.gov.co/direccion-de-asuntos-para-comunidades-negras-afrocolombianas-raizales-y-palenqueras/','Verificar representación y registro de consejos comunitarios y organizaciones NARP.'),
('mininterior_consulta_previa','Autoridad Nacional de Consulta Previa — sujetos de consulta','Ministerio del Interior','Comunidades indígenas; comunidades negras, afrocolombianas, raizales y palenqueras; pueblo Rrom','https://www.mininterior.gov.co/direccion-de-autoridad-nacional-y-consulta-previa/fundamentos-de-la-consulta-previa/','Determinar cuándo un proceso participativo ordinario debe complementarse o sustituirse por consulta previa formal.'),
('ant_territorios_etnicos','Información de tierras y territorios étnicos','Agencia Nacional de Tierras','Resguardos, reservas, territorios indígenas y tierras colectivas en el marco de sus competencias','https://www.ant.gov.co/glosario','Contrastar situación jurídica territorial y procesos de titulación/constitución/ampliación antes de publicar un ámbito como definitivo.'),
('dnp_planeacion_participativa','Planeación participativa','Departamento Nacional de Planeación','Sistema y metodologías de planeación participativa','https://www.dnp.gov.co/LaEntidad_/subdireccion-general-prospectiva-desarrollo-nacional/direccion-gobierno-ddhh-paz/Paginas/planeaci%C3%B3n-participativa.aspx','Referencia metodológica para procesos de visión, planes y retroalimentación ciudadana.')
on conflict(code) do update set
  name=excluded.name,responsible_authority=excluded.responsible_authority,coverage=excluded.coverage,url=excluded.url,use_in_consenso=excluded.use_in_consenso,active=true,updated_at=now();

create or replace view public.public_entity_type_catalog
with (security_invoker=true)
as
select code,name,family,branch_or_system,governance_level,role_kind,is_state_entity,is_collective_governance,
       competence_summary,typical_instruments,normative_basis,official_reference_url,notes,sort_order
from public.entity_type_catalog
where active=true;

grant select on public.public_entity_type_catalog to anon,authenticated;

create or replace view public.public_scope_type_catalog
with (security_invoker=true)
as
select code,name,family,level_order,is_ethnic_territorial,is_special_planning_scope,governance_notes,
       typical_instruments,normative_basis,official_reference_url,sort_order
from public.scope_type_catalog
where active=true;

grant select on public.public_scope_type_catalog to anon,authenticated;

create or replace view public.public_reference_registries
with (security_invoker=true)
as
select code,name,responsible_authority,coverage,url,use_in_consenso
from public.reference_registries
where active=true;

grant select on public.public_reference_registries to anon,authenticated;

create or replace view public.public_participation_scopes
with (security_invoker=true)
as
select id,name,scope_type_code,parent_scope_id,region,department,municipality,official_code,
       governing_authority_name,own_instrument,official_source_url,metadata,created_at,updated_at
from public.participation_scopes
where active=true;

grant select on public.public_participation_scopes to anon,authenticated;
