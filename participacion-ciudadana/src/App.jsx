import React, { useMemo, useState } from "react";
import { INSTITUTION_TYPES, THEMES } from "./lib/constants.js";

const OBS = import.meta.env.VITE_OBSERVATORIO_URL || "https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/";

const stages = [
  "Diagnóstico", "Reto", "Propuesta", "Deliberación", "Evaluación",
  "Priorización", "Votación", "Resultado", "Respuesta institucional",
  "Implementación", "Vigilancia", "Evaluación"
];

const qualityGates = [
  ["Competencia", "Quién puede decidir, sobre qué y con qué efecto jurídico."],
  ["Evidencia", "Línea base, fuentes verificables, procedencia y versiones."],
  ["Inclusión", "Accesibilidad, territorio, brecha digital y canales híbridos."],
  ["Deliberación", "Argumentos contrapuestos, evidencia, enmiendas y tiempo suficiente."],
  ["Evaluación", "Análisis jurídico, fiscal, técnico, social, ambiental y territorial."],
  ["Reglas congeladas", "Método, opciones, universo, fechas y umbrales antes de votar."],
  ["Integridad", "Anti-doble-voto, secreto cuando aplique, auditoría y hashes públicos."],
  ["Rendición de cuentas", "Respuesta institucional, implementación, indicadores y seguimiento."]
];

const trustLayers = [
  ["Código abierto", "GitHub conserva cambios, documentación y versión desplegada."],
  ["Datos operativos separados", "Proyecto Supabase/PostgreSQL propio para esta plataforma."],
  ["Procedencia", "Cada diagnóstico puede conservar origen, URL, versión, fecha y SHA-256."],
  ["Registro append-only", "Eventos críticos se encadenan criptográficamente para detectar alteraciones."],
  ["Checkpoints públicos", "Reglas, opciones, resultados y commit pueden publicarse como hashes verificables."],
  ["Blockchain opcional", "Se anclan hashes, nunca datos personales ni votos individuales."]
];

const diagnostics = [
  {
    id: "diag-001",
    title: "Hallazgos de legalidad e integridad como antecedente",
    source: "Observatorio Ciudadano de Legalidad y Transparencia",
    status: "Fuente hermana pública",
    description: "Una ficha pública del Observatorio puede convertirse en insumo de diagnóstico, pero requiere revisión humana antes de formular un reto o solución."
  },
  {
    id: "diag-002",
    title: "Planes, indicadores y datos abiertos",
    source: "Entidades públicas y sistemas oficiales",
    status: "Fuente primaria",
    description: "Planes vigentes, ejecución presupuestal, indicadores sectoriales, datos territoriales y evaluaciones alimentan la línea base."
  },
  {
    id: "diag-003",
    title: "Experiencia ciudadana y territorial",
    source: "Participación abierta y canales híbridos",
    status: "Evidencia participativa",
    description: "La experiencia de comunidades puede documentar problemas que no aparecen en los indicadores y debe contrastarse con fuentes y contexto."
  }
];

const seed = [
  {id:1,title:"Universidad pública regional y formación pertinente",scope:"Regional",theme:"Educación",stage:"Deliberación",support:684,summary:"Fortalecer oferta universitaria conectada con vocaciones productivas, científicas y sociales del territorio."},
  {id:2,title:"Plan nacional de agua y resiliencia climática",scope:"Nacional",theme:"Agua",stage:"Evaluación",support:1214,summary:"Priorizar abastecimiento, saneamiento, protección de cuencas y adaptación climática con metas verificables."},
  {id:3,title:"Red de innovación y bioeconomía territorial",scope:"Departamental",theme:"Ciencia y tecnología",stage:"Priorización",support:902,summary:"Articular universidades, comunidades, empresas y Estado alrededor de proyectos de innovación con impacto regional."}
];

export default function App(){
  const [view,setView]=useState("inicio");
  const [proposals,setProposals]=useState(seed);
  const [votes,setVotes]=useState({});
  const nav=[
    ["inicio","Inicio"],
    ["diagnostico","Diagnóstico"],
    ["propuestas","Propuestas"],
    ["proponer","Proponer"],
    ["priorizar","Priorizar"],
    ["instituciones","Instituciones"],
    ["integridad","Confianza"],
    ["metodo","Reglas"]
  ];

  return <div className="app">
    <header className="hero"><div className="wrap">
      <div className="eyebrow">DEMOCRACIA PARTICIPATIVA · PLANEACIÓN DE FUTURO · CÓDIGO ABIERTO</div>
      <h1>Colombia Construye Futuro</h1>
      <p>Infraestructura cívica para convertir evidencia y diagnóstico en propuestas, deliberación informada, prioridades democráticas y compromisos públicos verificables.</p>
      <div className="hero-actions">
        <button onClick={()=>setView("proponer")}>Crear propuesta</button>
        <button onClick={()=>setView("priorizar")} className="secondary">Priorizar</button>
        <a href={OBS}>Abrir Observatorio de Transparencia</a>
      </div>
    </div></header>

    <div className="wrap">
      <nav className="nav" aria-label="Navegación principal">
        {nav.map(([k,t])=><button className={view===k?"active":""} key={k} onClick={()=>setView(k)}>{t}</button>)}
      </nav>
      {view==="inicio"&&<Home setView={setView}/>} 
      {view==="diagnostico"&&<Diagnostico/>} 
      {view==="propuestas"&&<ProposalList proposals={proposals}/>} 
      {view==="proponer"&&<Proponer onAdd={p=>{setProposals([{...p,id:Date.now(),stage:"Propuesta",support:0},...proposals]);setView("propuestas")}}/>} 
      {view==="priorizar"&&<Priorizar proposals={proposals} votes={votes} setVotes={setVotes}/>} 
      {view==="instituciones"&&<Instituciones/>}
      {view==="integridad"&&<Integridad/>}
      {view==="metodo"&&<Metodo/>}
    </div>

    <footer><div className="wrap">
      Piloto de participación consultiva y trazable. Una votación de esta plataforma solo tendrá efectos jurídicos vinculantes cuando se integre formalmente al mecanismo y autoridad competentes. Código, reglas, metodología y resultados deben ser auditables.
    </div></footer>
  </div>;
}

function Home({setView}){
  return <main>
    <section className="loop">
      <h2>Participación que no termina en una encuesta</h2>
      <div className="loopline">{stages.map((s,i)=><React.Fragment key={`${s}-${i}`}><span>{s}</span>{i<stages.length-1&&<b>→</b>}</React.Fragment>)}</div>
      <p>Los resultados deben producir respuesta institucional y seguimiento. La evaluación vuelve a alimentar nuevos diagnósticos.</p>
    </section>

    <section className="grid3">
      <Card title="Construir visión" text="Horizontes país, territoriales e institucionales a 10, 20, 30 o más años, con escenarios, indicadores y decisiones trazables."/>
      <Card title="Construir normas y planes" text="Propuestas, articulados, planes de desarrollo, políticas, estrategias, proyectos y alianzas con historial de versiones."/>
      <Card title="Priorizar con legitimidad" text="Deliberación previa, evaluación técnica separada, reglas congeladas, votación verificable y cobertura territorial reportada."/>
    </section>

    <section className="callout">
      <h3>La transparencia puede ser el punto de partida</h3>
      <p>Los hallazgos públicos del Observatorio pueden alimentar el diagnóstico. La solución se construye aquí de forma independiente y nunca se deriva automáticamente del hallazgo.</p>
      <button onClick={()=>setView("diagnostico")}>Ver arquitectura de diagnóstico</button>
    </section>

    <section style={{marginTop:24}}>
      <h2>Ocho puertas de calidad</h2>
      <div className="grid2">{qualityGates.map(([title,text])=><Card key={title} title={title} text={text}/>)}</div>
    </section>
  </main>;
}

const Card=({title,text})=><article className="card"><h3>{title}</h3><p>{text}</p></article>;

function Diagnostico(){
  return <main>
    <h2>Diagnóstico con procedencia verificable</h2>
    <p className="muted">Toda propuesta de alto impacto debe explicar qué problema intenta resolver, con qué evidencia y quién tiene competencia para actuar.</p>
    {diagnostics.map(d=><article className="proposal" key={d.id}>
      <div className="tags"><span>{d.status}</span><span>Procedencia visible</span><span>Hashable</span></div>
      <h3>{d.title}</h3><p>{d.description}</p><div className="metrics">Fuente: {d.source}</div>
    </article>)}
    <a className="linkbox" href={OBS}>Consultar Observatorio Ciudadano de Legalidad y Transparencia →</a>
    <div className="rulebox" style={{marginTop:16}}><b>Regla de interoperabilidad</b><p>Solo se importa información pública. No se transfieren contactos privados, credenciales, notas internas ni datos reservados. Cada versión conserva URL de origen, fecha y hash.</p></div>
  </main>;
}

function ProposalList({proposals}){
  return <main><h2>Propuestas en construcción</h2>
    <p className="muted">La popularidad no reemplaza la deliberación. Cada propuesta debe avanzar por evidencia, discusión, evaluación y reglas de proceso.</p>
    {proposals.map(p=><article className="proposal" key={p.id}>
      <div className="tags"><span>{p.scope}</span><span>{p.theme}</span><span>{p.stage}</span></div>
      <h3>{p.title}</h3><p>{p.summary}</p>
      <div className="metrics"><b>{p.support}</b> apoyos preliminares · evaluación técnica separada · historial versionado · sin efecto vinculante automático</div>
    </article>)}
  </main>;
}

function Proponer({onAdd}){
  const [v,setV]=useState({title:"",summary:"",scope:"Nacional",theme:THEMES[0],institution:"",institutionType:INSTITUTION_TYPES[0],problem:"",evidence:"",outcome:"",competence:"",indicator:""});
  const set=(k,x)=>setV({...v,[k]:x});
  return <main><h2>Crear propuesta</h2>
    <p className="muted">Primero problema, evidencia y competencia; después solución. El borrador deberá deliberarse antes de una eventual priorización.</p>
    <div className="form grid2">
      <Field l="Título" value={v.title} onChange={x=>set("title",x)}/>
      <Field l="Ámbito" value={v.scope} onChange={x=>set("scope",x)} options={["Nacional","Regional","Departamental","Distrital","Municipal","Local","Institucional"]}/>
      <Field l="Tema" value={v.theme} onChange={x=>set("theme",x)} options={THEMES}/>
      <Field l="Tipo de institución" value={v.institutionType} onChange={x=>set("institutionType",x)} options={INSTITUTION_TYPES}/>
      <Field l="Institución relacionada" value={v.institution} onChange={x=>set("institution",x)}/>
      <Field l="Competencia / responsable" value={v.competence} onChange={x=>set("competence",x)}/>
      <Field l="Resultado esperado" value={v.outcome} onChange={x=>set("outcome",x)}/>
      <Field l="Indicador de éxito" value={v.indicator} onChange={x=>set("indicator",x)}/>
      <Area l="Problema / diagnóstico" value={v.problem} onChange={x=>set("problem",x)}/>
      <Area l="Resumen de la propuesta" value={v.summary} onChange={x=>set("summary",x)}/>
      <Area l="Evidencia / fuentes" value={v.evidence} onChange={x=>set("evidence",x)}/>
    </div>
    <button onClick={()=>{if(v.title.trim().length<8||v.summary.trim().length<40||v.problem.trim().length<40)return alert("Completa título, diagnóstico y propuesta con suficiente detalle.");onAdd(v)}}>Guardar borrador trazable</button>
  </main>;
}

function Field({l,value,onChange,options}){
  return <label><span>{l}</span>{options?<select value={value} onChange={e=>onChange(e.target.value)}>{options.map(x=><option key={x}>{x}</option>)}</select>:<input value={value} onChange={e=>onChange(e.target.value)}/>}</label>;
}
function Area({l,value,onChange}){return <label className="full"><span>{l}</span><textarea rows="4" value={value} onChange={e=>onChange(e.target.value)}/></label>}

function Priorizar({proposals,votes,setVotes}){
  const total=Object.values(votes).reduce((a,b)=>a+b,0);
  const remain=100-total;
  const ranked=useMemo(()=>proposals.map(p=>({...p,points:votes[p.id]||0})).sort((a,b)=>b.points-a.points),[proposals,votes]);
  return <main><h2>Prioridades ciudadanas</h2>
    <div className="rulebox"><b>Demostración: 100 puntos por persona</b><p>Distribúyelos entre alternativas. En un proceso real, el método, universo, opciones, periodo, umbrales, criterio territorial y fórmula se publican y congelan antes de abrir.</p><strong>Disponibles: {remain}</strong></div>
    {ranked.map(p=><article className="vote" key={p.id}>
      <div><h3>{p.title}</h3><small>{p.scope} · {p.theme}</small></div>
      <input aria-label={`Puntos para ${p.title}`} type="number" min="0" max="100" value={votes[p.id]||0} onChange={e=>{const n=Math.max(0,Math.min(100,Number(e.target.value)||0));const next={...votes,[p.id]:n};if(Object.values(next).reduce((a,b)=>a+b,0)<=100)setVotes(next)}}/>
      <b>{votes[p.id]||0} pts</b>
    </article>)}
    <div className="rulebox"><b>Esto no declara consenso</b><p>Para declarar una prioridad amplia deben cumplirse también participación, cobertura territorial, deliberación, evaluación técnica e integridad según reglas previas.</p></div>
  </main>;
}

function Instituciones(){
  return <main><h2>Participación en todos los niveles e instituciones</h2>
    <p className="muted">Cada proceso identifica competencia, territorio, autoridad responsable y efecto esperado.</p>
    <div className="grid2">
      <Card title="Territorial" text="Nación, regiones, departamentos, distritos, municipios y niveles locales cuando corresponda."/>
      <Card title="Administración pública" text="Ministerios, departamentos administrativos, superintendencias, agencias, establecimientos y unidades administrativas especiales."/>
      <Card title="Autonomía e instituciones" text="Universidades públicas, corporaciones autónomas regionales y otros organismos con regímenes propios, respetando sus competencias."/>
      <Card title="Procesos especiales" text="La plataforma no reemplaza consulta previa, mecanismos electorales, participación ambiental u otros procedimientos con garantías jurídicas específicas."/>
    </div>
  </main>;
}

function Integridad(){
  return <main><h2>Arquitectura pública de confianza</h2>
    <p className="muted">La transparencia se construye por capas. Blockchain puede reforzar integridad, pero no sustituye reglas democráticas, privacidad ni auditoría.</p>
    <div className="grid2">{trustLayers.map(([title,text])=><Card key={title} title={title} text={text}/>)}</div>
    <div className="callout"><h3>Qué se ancla</h3><p>Hashes de reglas, opciones, lotes de recibos, resultados, evidencia pública y versión de software. Nunca datos personales, votos individuales ni información reservada.</p></div>
  </main>;
}

function Metodo(){
  return <main><h2>Reglas de legitimidad</h2>
    <div className="grid2">
      <Card title="Participación significativa" text="Solo se abre un proceso si existe una decisión, problema o política sobre la cual la ciudadanía puede influir de manera explicable."/>
      <Card title="Identidad y voto" text="Lectura abierta. El nivel de verificación depende del riesgo. Una persona habilitada no vota dos veces y la selección se separa de la identidad cuando corresponda."/>
      <Card title="Reglas antes del voto" text="Método, quorum, periodo, elegibilidad, territorio, opciones, empates y umbrales se publican y congelan antes de abrir."/>
      <Card title="Deliberación informada" text="Argumentos a favor, en contra y alternativas; evidencia enlazada; versiones; contestación; moderación motivada y apelable."/>
      <Card title="Evaluación técnica separada" text="Expertos evalúan viabilidad, costos, riesgos e impactos, pero su criterio no multiplica el voto ciudadano."/>
      <Card title="Consenso exigente" text="Consenso no equivale a mayoría simple: requiere reglas previas sobre apoyo, participación, cobertura territorial e integridad."/>
      <Card title="IA limitada y auditable" text="Puede resumir, traducir, agrupar y detectar señales de abuso. No define ganadores, elegibilidad ni censura definitiva sin revisión humana."/>
      <Card title="Inclusión y accesibilidad" text="WCAG 2.1 AA como mínimo, lenguaje claro, móvil y canales presenciales/asistidos con control contra doble contabilización."/>
      <Card title="Privacidad por diseño" text="Minimización, finalidades explícitas, retención limitada, separación de identidad y preferencia y auditoría de accesos."/>
      <Card title="Efecto jurídico visible" text="Cada resultado muestra si es exploratorio, consultivo, de co-creación, priorización o parte de un mecanismo formal competente."/>
    </div>
  </main>;
}
