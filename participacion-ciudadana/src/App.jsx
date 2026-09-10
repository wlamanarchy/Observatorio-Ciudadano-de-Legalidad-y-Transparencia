import React,{useEffect,useState} from 'react';
import { THEMES } from './lib/constants.js';
import {
  backendMode,getSession,onAuthChange,signInWithEmail,signOut,listProcesses,listDiagnostics,listProposals,
  listContributions,createProposal,createContribution,listBallots,getBallotOptions,requestEligibility,castVote
} from './lib/store.js';

const OBS=import.meta.env.VITE_OBSERVATORIO_URL||'https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/';
const STAGES=['Diagnóstico','Reto','Propuesta','Deliberación','Evaluación','Priorización','Votación','Respuesta institucional','Implementación','Vigilancia','Evaluación'];
const CTYPE={supporting_argument:'A favor',opposing_argument:'En contra',alternative:'Alternativa',question:'Pregunta',amendment:'Enmienda',evidence:'Evidencia'};

export default function App(){
  const [view,setView]=useState('inicio');
  const [data,setData]=useState({processes:[],diagnostics:[],proposals:[],ballots:[]});
  const [auth,setAuth]=useState({user:null,profile:null});
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState('');
  const [notice,setNotice]=useState('');

  async function refresh(){
    setLoading(true); setError('');
    try{
      const [processes,diagnostics,proposals,ballots,session]=await Promise.all([
        listProcesses(),listDiagnostics(),listProposals(),listBallots(),getSession()
      ]);
      setData({processes,diagnostics,proposals,ballots}); setAuth(session);
    }catch(e){setError(e?.message||'No fue posible cargar la plataforma.');}
    finally{setLoading(false);}
  }

  useEffect(()=>{refresh();const off=onAuthChange(setAuth);return off;},[]);

  const nav=[['inicio','Inicio'],['diagnostico','Diagnóstico'],['propuestas','Propuestas'],['proponer','Proponer'],['votar','Votar'],['metodo','Reglas'],['cuenta',auth.user?'Mi cuenta':'Ingresar']];
  return <div className="app">
    <header className="hero"><div className="wrap">
      <div className="eyebrow">DEMOCRACIA PARTICIPATIVA · PLANEACIÓN ABIERTA · TRAZABILIDAD</div>
      <h1>Colombia Construye Futuro</h1>
      <p>Infraestructura cívica para transformar evidencia y diagnósticos en propuestas, deliberación, prioridades y seguimiento público.</p>
      <div className="hero-actions"><button onClick={()=>setView('proponer')}>Presentar propuesta</button><button className="secondary" onClick={()=>setView('votar')}>Participar en votaciones</button><a href={OBS}>Abrir plataforma hermana de Transparencia</a></div>
    </div></header>

    <div className="wrap">
      <div className="statusbar"><span><b>Modo:</b> {backendMode()==='supabase'?'piloto conectado':'demostración local'}</span><span><b>Sesión:</b> {auth.user?auth.user.email:'pública'}</span><span><b>Principio:</b> evidencia → deliberación → decisión trazable</span></div>
      {error&&<div className="alert error">{error}</div>}{notice&&<div className="alert">{notice}</div>}
      <nav className="nav">{nav.map(([k,t])=><button key={k} className={view===k?'active':''} onClick={()=>setView(k)}>{t}</button>)}</nav>
      {loading?<main><div className="card">Cargando información pública y procesos…</div></main>:<>
        {view==='inicio'&&<Home data={data} setView={setView}/>} 
        {view==='diagnostico'&&<Diagnostico diagnostics={data.diagnostics}/>} 
        {view==='propuestas'&&<ProposalList proposals={data.proposals} auth={auth} onRefresh={refresh} setNotice={setNotice}/>} 
        {view==='proponer'&&<Proponer processes={data.processes} auth={auth} onCreated={async()=>{await refresh();setNotice('Propuesta registrada con trazabilidad de versión.');setView('propuestas')}}/>}
        {view==='votar'&&<Voting ballots={data.ballots} auth={auth} setNotice={setNotice}/>} 
        {view==='metodo'&&<Metodo/>}
        {view==='cuenta'&&<Cuenta auth={auth} onRefresh={refresh} setNotice={setNotice}/>} 
      </>}
    </div>
    <footer><div className="wrap">La plataforma distingue participación consultiva, priorización ciudadana y mecanismos jurídicamente vinculantes. Un resultado digital no adquiere efectos jurídicos por el solo hecho de ser votado.</div></footer>
  </div>;
}

function Home({data,setView}){
  return <main>
    <section className="loop"><h2>De la evidencia a una visión compartida</h2><div className="loopline">{STAGES.map((s,i)=><React.Fragment key={`${s}-${i}`}><span>{s}</span>{i<STAGES.length-1&&<b>→</b>}</React.Fragment>)}</div><p>El objetivo no es recolectar opiniones aisladas: es dejar una cadena pública de diagnóstico, deliberación, decisión, respuesta institucional y resultados.</p></section>
    <section className="grid3"><Metric title="Procesos abiertos" n={data.processes.length}/><Metric title="Propuestas visibles" n={data.proposals.length}/><Metric title="Votaciones publicadas" n={data.ballots.length}/></section>
    <section className="grid3" style={{marginTop:16}}><Card title="Construir futuro" text="Visiones nacionales, territoriales e institucionales con horizontes verificables."/><Card title="Construir normas y planes" text="Propuestas, articulados, estrategias, proyectos, alianzas y planes con historial de versiones."/><Card title="Priorizar democráticamente" text="Reglas publicadas antes del voto, evaluación técnica separada y resultados auditables."/></section>
    <section className="callout"><h3>La transparencia es una fuente de diagnóstico, no una orden política</h3><p>Los hallazgos públicos del Observatorio pueden originar retos o preguntas. La ciudadanía conserva autonomía para proponer, disentir, deliberar y priorizar alternativas.</p><div className="hero-actions"><button onClick={()=>setView('diagnostico')}>Explorar diagnóstico</button><a href={OBS}>Consultar Observatorio</a></div></section>
  </main>;
}
const Metric=({title,n})=><article className="card"><small className="eyebrow dark">{title}</small><div className="metricBig">{n}</div></article>;
const Card=({title,text})=><article className="card"><h3>{title}</h3><p>{text}</p></article>;

function Diagnostico({diagnostics}){
  return <main><h2>Diagnóstico para decidir mejor</h2><p className="muted">Cada diagnóstico debe ser verificable, fechado y vinculado a fuentes. La interoperabilidad con Transparencia usa únicamente información pública y conserva procedencia.</p>
    {!diagnostics.length&&<div className="grid2"><Card title="Datos públicos" text="Indicadores, planes vigentes, información oficial, evidencia territorial y resultados de políticas."/><Card title="Observatorio de Transparencia" text="Hallazgos públicos pueden alimentar retos de reforma o prevención sin convertirse automáticamente en una solución aprobada."/></div>}
    {diagnostics.map(d=><article className="proposal" key={d.id}><div className="tags"><span>Diagnóstico</span>{d.observatory_reference&&<span>Referencia Observatorio</span>}</div><h3>{d.title}</h3><p>{d.description}</p>{d.source_url&&<a href={d.source_url}>Fuente pública</a>}</article>)}
    <a className="linkbox" href={OBS}>Consultar evidencia en el Observatorio Ciudadano de Legalidad y Transparencia →</a>
  </main>;
}

function ProposalList({proposals,auth,onRefresh,setNotice}){
  const [open,setOpen]=useState(null);
  return <main><h2>Propuestas en construcción</h2><p className="muted">El apoyo preliminar no determina el resultado. La deliberación, evidencia, evaluación y reglas del proceso permanecen separadas.</p>
    {!proposals.length&&<div className="card">Aún no hay propuestas publicadas.</div>}
    {proposals.map(p=><Proposal key={p.id} p={p} open={open===p.id} onToggle={()=>setOpen(open===p.id?null:p.id)} auth={auth} onRefresh={onRefresh} setNotice={setNotice}/>)}</main>;
}

function Proposal({p,open,onToggle,auth,onRefresh,setNotice}){
  const [contribs,setContribs]=useState([]);const [type,setType]=useState('supporting_argument');const [body,setBody]=useState('');const [source,setSource]=useState('');const [busy,setBusy]=useState(false);
  useEffect(()=>{if(open)listContributions(p.id).then(setContribs).catch(()=>setContribs([]));},[open,p.id]);
  async function submit(){if(!auth.user)return setNotice('Ingresa con tu correo para participar en la deliberación.');if(body.trim().length<20)return setNotice('El aporte debe tener al menos 20 caracteres.');setBusy(true);try{await createContribution({proposalId:p.id,type,body,sourceUrl:source});setBody('');setSource('');setContribs(await listContributions(p.id));await onRefresh();setNotice('Aporte registrado.');}catch(e){setNotice(e?.message||'No fue posible registrar el aporte.');}finally{setBusy(false)}}
  return <article className="proposal"><div className="tags"><span>{p.scope_level||'Sin ámbito'}</span>{p.theme&&<span>{p.theme}</span>}<span>{p.status}</span></div><h3>{p.title}</h3><p>{p.summary}</p><div className="metrics">{p.contribution_count||0} aportes públicos · historial versionado</div><button onClick={onToggle}>{open?'Cerrar deliberación':'Abrir deliberación'}</button>
    {open&&<div className="delib"><h4>Problema identificado</h4><p>{p.problem}</p>{p.expected_outcome&&<><h4>Resultado esperado</h4><p>{p.expected_outcome}</p></>}
      <h4>Aportes</h4>{!contribs.length&&<p className="muted">Aún no hay aportes visibles.</p>}{contribs.map(c=><div className="contribution" key={c.id}><b>{CTYPE[c.contribution_type]||c.contribution_type}</b><p>{c.body}</p>{c.source_url&&<a href={c.source_url}>Fuente</a>}</div>)}
      <div className="form grid2"><label><span>Tipo de aporte</span><select value={type} onChange={e=>setType(e.target.value)}>{Object.entries(CTYPE).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select></label><label><span>Fuente opcional</span><input value={source} onChange={e=>setSource(e.target.value)} placeholder="https://…"/></label><label className="full"><span>Tu aporte</span><textarea rows="4" value={body} onChange={e=>setBody(e.target.value)}/></label></div><button disabled={busy} onClick={submit}>{busy?'Guardando…':'Publicar aporte'}</button>
    </div>}
  </article>;
}

function Proponer({processes,auth,onCreated}){
  const [v,setV]=useState({processId:processes[0]?.id||'',title:'',summary:'',problem:'',expectedOutcome:'',theme:THEMES[0],scopeLevel:'nacional',region:'',department:'',municipality:'',evidenceUrl:''});
  const [busy,setBusy]=useState(false);const [msg,setMsg]=useState('');const set=(k,x)=>setV({...v,[k]:x});
  async function submit(){if(!auth.user)return setMsg('Debes ingresar para registrar una propuesta trazable.');if(!v.processId)return setMsg('No hay un proceso abierto para recibir esta propuesta.');setBusy(true);setMsg('');try{await createProposal({...v,evidence:v.evidenceUrl?[{url:v.evidenceUrl}]:[]});await onCreated();}catch(e){setMsg(e?.message||'No fue posible registrar la propuesta.');}finally{setBusy(false)}}
  return <main><h2>Presentar propuesta</h2><p className="muted">Una propuesta debe partir de un problema verificable y quedar asociada a un proceso público.</p>{!auth.user&&<div className="alert">Puedes preparar el formulario, pero necesitarás ingresar antes de enviarlo.</div>}
    <div className="form grid2"><Field l="Proceso" value={v.processId} onChange={x=>set('processId',x)} options={processes.map(p=>({value:p.id,label:p.title}))}/><Field l="Título" value={v.title} onChange={x=>set('title',x)}/><Field l="Ámbito" value={v.scopeLevel} onChange={x=>set('scopeLevel',x)} options={['nacional','regional','departamental','distrital','municipal','local','institucional']}/><Field l="Tema" value={v.theme} onChange={x=>set('theme',x)} options={THEMES}/><Field l="Región" value={v.region} onChange={x=>set('region',x)}/><Field l="Departamento" value={v.department} onChange={x=>set('department',x)}/><Field l="Municipio / distrito" value={v.municipality} onChange={x=>set('municipality',x)}/><Field l="Resultado esperado" value={v.expectedOutcome} onChange={x=>set('expectedOutcome',x)}/><Area l="Problema / diagnóstico" value={v.problem} onChange={x=>set('problem',x)}/><Area l="Propuesta" value={v.summary} onChange={x=>set('summary',x)}/><Field l="Fuente pública inicial" value={v.evidenceUrl} onChange={x=>set('evidenceUrl',x)}/></div>{msg&&<div className="alert">{msg}</div>}<button disabled={busy} onClick={submit}>{busy?'Registrando…':'Registrar propuesta'}</button>
  </main>;
}
function Field({l,value,onChange,options}){return <label><span>{l}</span>{options?<select value={value} onChange={e=>onChange(e.target.value)}><option value="">Seleccione</option>{options.map(x=>typeof x==='string'?<option key={x} value={x}>{x}</option>:<option key={x.value} value={x.value}>{x.label}</option>)}</select>:<input value={value} onChange={e=>onChange(e.target.value)}/>}</label>}
function Area({l,value,onChange}){return <label className="full"><span>{l}</span><textarea rows="5" value={value} onChange={e=>onChange(e.target.value)}/></label>}

function Voting({ballots,auth,setNotice}){
  const [selected,setSelected]=useState(null);const [options,setOptions]=useState([]);const [choice,setChoice]=useState({});const [busy,setBusy]=useState(false);
  async function open(b){setSelected(b);setChoice({});try{setOptions(await getBallotOptions(b.ballot_id));}catch(e){setNotice(e?.message||'No fue posible cargar las opciones.')}}
  async function request(){if(!auth.user)return setNotice('Ingresa para solicitar habilitación.');try{await requestEligibility(selected.ballot_id,'Solicitud desde la plataforma ciudadana');setNotice('Solicitud de habilitación registrada.');}catch(e){setNotice(e?.message||'No fue posible solicitar habilitación.')}}
  async function vote(){if(!auth.user)return setNotice('Ingresa para votar.');let selection;if(selected.method==='yes_no')selection={choice:choice.answer||''};else if(selected.method==='approval')selection={option_ids:Object.keys(choice).filter(k=>choice[k])};else if(selected.method==='points100')selection={points:Object.fromEntries(options.map(o=>[o.id,Number(choice[o.id]||0)]))};else return setNotice('Este método requiere una interfaz específica que se habilitará para el proceso.');setBusy(true);try{const receipt=await castVote(selected.ballot_id,selection);setNotice(`Voto registrado. Conserva tu recibo de integridad: ${receipt}`);}catch(e){setNotice(e?.message||'No fue posible registrar el voto.');}finally{setBusy(false)}}
  return <main><h2>Votaciones y priorización</h2><div className="rulebox"><b>La regla antecede al voto.</b><p>Método, elegibilidad, fechas, opciones y umbrales deben estar congelados antes de abrir una votación.</p></div>{!ballots.length&&<div className="card">No hay votaciones abiertas o publicadas en este momento.</div>}{ballots.map(b=><article className="proposal" key={b.ballot_id}><div className="tags"><span>{b.status}</span><span>{b.method}</span><span>Integridad: {b.integrity_level}</span></div><h3>{b.title}</h3><div className="metrics">Participantes: {b.participant_count??'—'} · elegibles: {b.eligible_count??'—'} · votos: {b.vote_count??'—'}</div><button onClick={()=>open(b)}>Abrir boleta</button></article>)}
    {selected&&<section className="modalCard"><h3>{selected.title}</h3>{selected.method==='yes_no'&&<div className="radioGroup">{['yes','no','abstain'].map(x=><label key={x}><input type="radio" name="yn" checked={choice.answer===x} onChange={()=>setChoice({answer:x})}/>{x==='yes'?'Sí':x==='no'?'No':'Abstención'}</label>)}</div>}{selected.method==='approval'&&options.map(o=><label className="checkline" key={o.id}><input type="checkbox" checked={!!choice[o.id]} onChange={e=>setChoice({...choice,[o.id]:e.target.checked})}/>{o.label}</label>)}{selected.method==='points100'&&options.map(o=><label className="vote" key={o.id}><span>{o.label}</span><input type="number" min="0" max="100" value={choice[o.id]||0} onChange={e=>setChoice({...choice,[o.id]:Math.max(0,Math.min(100,Number(e.target.value)||0))})}/><b>{choice[o.id]||0}</b></label>)}<div className="hero-actions"><button onClick={request}>Solicitar habilitación</button><button disabled={busy||selected.status!=='open'} onClick={vote}>{busy?'Registrando…':'Emitir voto'}</button></div></section>}
  </main>;
}

function Cuenta({auth,onRefresh,setNotice}){const [email,setEmail]=useState('');const [busy,setBusy]=useState(false);if(auth.user)return <main><h2>Mi cuenta</h2><div className="card"><p><b>{auth.profile?.display_name||auth.user.email}</b></p><p>{auth.user.email}</p><p className="muted">Nivel de verificación: {auth.profile?.verification_level??'pendiente'}</p><button onClick={async()=>{await signOut();await onRefresh();setNotice('Sesión cerrada.')}}>Cerrar sesión</button></div></main>;return <main><h2>Ingresar para participar</h2><div className="card"><p>Usamos acceso sin contraseña por correo. La lectura pública no requiere cuenta.</p><div className="form"><label><span>Correo electrónico</span><input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="tu@correo.com"/></label></div><button disabled={busy} onClick={async()=>{if(!email.includes('@'))return setNotice('Escribe un correo válido.');setBusy(true);const {error}=await signInWithEmail(email);setBusy(false);setNotice(error?error.message:'Revisa tu correo y abre el enlace de acceso.');}}>{busy?'Enviando…':'Enviar enlace de acceso'}</button></div></main>}

function Metodo(){return <main><h2>Reglas de legitimidad</h2><div className="grid2"><Card title="Igualdad política" text="La profesión, el patrimonio, el cargo o el conocimiento técnico no multiplican el voto de una persona."/><Card title="Reglas congeladas" text="Método, universo, opciones, fechas, umbrales y desempates se publican antes de abrir la votación."/><Card title="Deliberación informada" text="Argumentos a favor, en contra, alternativas, preguntas, enmiendas y evidencia quedan diferenciados."/><Card title="Evaluación técnica separada" text="Expertos analizan viabilidad jurídica, fiscal, ambiental, social y operativa sin alterar el peso democrático."/><Card title="Transparencia verificable" text="Versiones, reglas, resultados e hitos críticos generan hashes y pueden anclarse externamente sin publicar datos personales."/><Card title="Privacidad y secreto" text="Identidad, elegibilidad y selección se separan. Nunca se publica PII o voto individual en blockchain."/><Card title="IA subordinada" text="Puede ayudar a resumir, traducir, agrupar y detectar señales de abuso; no decide ganadores ni elimina posiciones por criterio ideológico."/><Card title="Naturaleza jurídica visible" text="Cada resultado indica si es consultivo, una prioridad participativa o parte de un mecanismo formalmente vinculante."/></div></main>}
