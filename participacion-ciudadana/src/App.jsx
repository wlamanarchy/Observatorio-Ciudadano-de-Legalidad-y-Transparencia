import React,{useEffect,useMemo,useState} from 'react';
import {INSTITUTION_TYPES,THEMES} from './lib/constants.js';
import {
  backendMode,getSession,onAuthChange,signInWithEmail,signOut,listProcesses,listDiagnostics,listProposals,
  listContributions,createProposal,createContribution,listBallots,listBallotResults,getBallotOptions,requestEligibility,castVote,
  bootstrapPlatformAdmin,adminUserDirectory,adminListGovernanceRoles,adminAssignRole,adminRevokeRole,adminSetVerification,
  adminPendingEligibility,adminDecideEligibility,adminListProcesses,adminListBallots,adminCreateInstitution,adminCreateProcess,
  adminSetProcessStatus,adminPublishConsensusRules,adminCreateBallot,adminAddBallotOption,adminOpenBallot,adminCloseAndTally,adminCertifyBallot
} from './lib/store.js';

const OBS=import.meta.env.VITE_OBSERVATORIO_URL||'https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/';
const STAGES=['Diagnóstico','Reto','Propuesta','Deliberación','Evaluación','Priorización','Votación','Respuesta institucional','Implementación','Vigilancia','Evaluación'];
const CTYPE={supporting_argument:'A favor',opposing_argument:'En contra',alternative:'Alternativa',question:'Pregunta',amendment:'Enmienda',evidence:'Evidencia'};
const GOV_ROLES=['platform_admin','methodology_admin','institution_admin','process_facilitator','moderator','technical_evaluator','independent_auditor','data_steward'];
const PROCESS_STATUS=['draft','diagnostic','deliberation','evaluation','prioritization','voting','response','implementation','closed'];
const isAdminish=roles=>(roles||[]).some(r=>['platform_admin','methodology_admin','institution_admin','process_facilitator','independent_auditor'].includes(r.role));

export default function App(){
  const [view,setView]=useState('inicio');
  const [data,setData]=useState({processes:[],diagnostics:[],proposals:[],ballots:[],results:[]});
  const [auth,setAuth]=useState({user:null,profile:null,roles:[]});
  const [loading,setLoading]=useState(true);const [error,setError]=useState('');const [notice,setNotice]=useState('');

  async function refresh(){
    setLoading(true);setError('');
    try{
      const [processes,diagnostics,proposals,ballots,results,session]=await Promise.all([
        listProcesses(),listDiagnostics(),listProposals(),listBallots(),listBallotResults(),getSession()
      ]);
      setData({processes,diagnostics,proposals,ballots,results});setAuth(session);
    }catch(e){setError(e?.message||'No fue posible cargar la plataforma.');}
    finally{setLoading(false);}
  }
  useEffect(()=>{refresh();const off=onAuthChange(setAuth);return off;},[]);

  const nav=[['inicio','Inicio'],['diagnostico','Diagnóstico'],['propuestas','Propuestas'],['proponer','Proponer'],['votar','Votar'],['resultados','Resultados'],['metodo','Reglas'],['cuenta',auth.user?'Mi cuenta':'Ingresar']];
  if(auth.user&&isAdminish(auth.roles))nav.push(['admin','Administración']);

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
      <nav className="nav" aria-label="Navegación principal">{nav.map(([k,t])=><button key={k} className={view===k?'active':''} onClick={()=>setView(k)}>{t}</button>)}</nav>
      {loading?<main><div className="card">Cargando información pública y procesos…</div></main>:<>
        {view==='inicio'&&<Home data={data} setView={setView}/>} 
        {view==='diagnostico'&&<Diagnostico diagnostics={data.diagnostics}/>} 
        {view==='propuestas'&&<ProposalList proposals={data.proposals} auth={auth} onRefresh={refresh} setNotice={setNotice}/>} 
        {view==='proponer'&&<Proponer processes={data.processes} auth={auth} onCreated={async()=>{await refresh();setNotice('Propuesta registrada con trazabilidad de versión.');setView('propuestas')}}/>}
        {view==='votar'&&<Voting ballots={data.ballots} auth={auth} setNotice={setNotice} onRefresh={refresh}/>} 
        {view==='resultados'&&<Resultados results={data.results} ballots={data.ballots}/>} 
        {view==='metodo'&&<Metodo/>}
        {view==='cuenta'&&<Cuenta auth={auth} onRefresh={refresh} setNotice={setNotice}/>} 
        {view==='admin'&&auth.user&&isAdminish(auth.roles)&&<AdminConsole auth={auth} publicData={data} onRefresh={refresh} setNotice={setNotice}/>} 
      </>}
    </div>
    <footer><div className="wrap">La plataforma distingue participación consultiva, priorización ciudadana y mecanismos jurídicamente vinculantes. Un resultado digital no adquiere efectos jurídicos por el solo hecho de ser votado.</div></footer>
  </div>;
}

function Home({data,setView}){return <main>
  <section className="loop"><h2>De la evidencia a una visión compartida</h2><div className="loopline">{STAGES.map((s,i)=><React.Fragment key={`${s}-${i}`}><span>{s}</span>{i<STAGES.length-1&&<b>→</b>}</React.Fragment>)}</div><p>El objetivo no es recolectar opiniones aisladas: es dejar una cadena pública de diagnóstico, deliberación, decisión, respuesta institucional y resultados.</p></section>
  <section className="grid3"><Metric title="Procesos abiertos" n={data.processes.length}/><Metric title="Propuestas visibles" n={data.proposals.length}/><Metric title="Votaciones publicadas" n={data.ballots.length}/></section>
  <section className="grid3 sectionGap"><Card title="Construir futuro" text="Visiones nacionales, territoriales e institucionales con horizontes verificables."/><Card title="Construir normas y planes" text="Propuestas, articulados, estrategias, proyectos, alianzas y planes con historial de versiones."/><Card title="Priorizar democráticamente" text="Reglas publicadas antes del voto, evaluación técnica separada y resultados auditables."/></section>
  <section className="callout"><h3>La transparencia es una fuente de diagnóstico, no una orden política</h3><p>Los hallazgos públicos del Observatorio pueden originar retos o preguntas. La ciudadanía conserva autonomía para proponer, disentir, deliberar y priorizar alternativas.</p><div className="hero-actions"><button onClick={()=>setView('diagnostico')}>Explorar diagnóstico</button><a href={OBS}>Consultar Observatorio</a></div></section>
</main>}
const Metric=({title,n})=><article className="card"><small className="eyebrow dark">{title}</small><div className="metricBig">{n}</div></article>;
const Card=({title,text})=><article className="card"><h3>{title}</h3><p>{text}</p></article>;

function Diagnostico({diagnostics}){return <main><h2>Diagnóstico para decidir mejor</h2><p className="muted">Cada diagnóstico debe ser verificable, fechado y vinculado a fuentes. La interoperabilidad con Transparencia usa únicamente información pública y conserva procedencia.</p>
  {!diagnostics.length&&<div className="card">Aún no hay diagnósticos públicos.</div>}
  {diagnostics.map(d=><article className="proposal" key={d.id}><div className="tags"><span>Diagnóstico</span>{d.observatory_reference&&<span>Referencia Observatorio</span>}</div><h3>{d.title}</h3><p>{d.description}</p>{d.source_url&&<a href={d.source_url}>Fuente pública</a>}</article>)}
  <a className="linkbox" href={OBS}>Consultar evidencia en el Observatorio Ciudadano de Legalidad y Transparencia →</a>
</main>}

function ProposalList({proposals,auth,onRefresh,setNotice}){const[open,setOpen]=useState(null);return <main><h2>Propuestas en construcción</h2><p className="muted">El apoyo preliminar no determina el resultado. La deliberación, evidencia, evaluación y reglas del proceso permanecen separadas.</p>
  {!proposals.length&&<div className="card">Aún no hay propuestas publicadas. La ciudadanía puede inaugurar el proceso desde “Proponer”.</div>}
  {proposals.map(p=><Proposal key={p.id} p={p} open={open===p.id} onToggle={()=>setOpen(open===p.id?null:p.id)} auth={auth} onRefresh={onRefresh} setNotice={setNotice}/>)}</main>}
function Proposal({p,open,onToggle,auth,onRefresh,setNotice}){
  const[contribs,setContribs]=useState([]);const[type,setType]=useState('supporting_argument');const[body,setBody]=useState('');const[source,setSource]=useState('');const[busy,setBusy]=useState(false);
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
  const[v,setV]=useState({processId:processes[0]?.id||'',title:'',summary:'',problem:'',expectedOutcome:'',theme:THEMES[0],scopeLevel:'nacional',region:'',department:'',municipality:'',evidenceUrl:''});
  const[busy,setBusy]=useState(false);const[msg,setMsg]=useState('');const set=(k,x)=>setV({...v,[k]:x});
  useEffect(()=>{if(!v.processId&&processes[0]?.id)setV(x=>({...x,processId:processes[0].id}));},[processes,v.processId]);
  async function submit(){if(!auth.user)return setMsg('Debes ingresar para registrar una propuesta trazable.');if(!v.processId)return setMsg('No hay un proceso abierto para recibir esta propuesta.');setBusy(true);setMsg('');try{await createProposal({...v,evidence:v.evidenceUrl?[{url:v.evidenceUrl}]:[]});await onCreated();}catch(e){setMsg(e?.message||'No fue posible registrar la propuesta.');}finally{setBusy(false)}}
  return <main><h2>Presentar propuesta</h2><p className="muted">Una propuesta debe partir de un problema verificable y quedar asociada a un proceso público.</p>{!auth.user&&<div className="alert">Puedes preparar el formulario, pero necesitarás ingresar antes de enviarlo.</div>}
    <div className="form grid2"><Field l="Proceso" value={v.processId} onChange={x=>set('processId',x)} options={processes.map(p=>({value:p.id,label:p.title}))}/><Field l="Título" value={v.title} onChange={x=>set('title',x)}/><Field l="Ámbito" value={v.scopeLevel} onChange={x=>set('scopeLevel',x)} options={['nacional','regional','departamental','distrital','municipal','local','institucional']}/><Field l="Tema" value={v.theme} onChange={x=>set('theme',x)} options={THEMES}/><Field l="Región" value={v.region} onChange={x=>set('region',x)}/><Field l="Departamento" value={v.department} onChange={x=>set('department',x)}/><Field l="Municipio / distrito" value={v.municipality} onChange={x=>set('municipality',x)}/><Field l="Resultado esperado" value={v.expectedOutcome} onChange={x=>set('expectedOutcome',x)}/><Area l="Problema / diagnóstico" value={v.problem} onChange={x=>set('problem',x)}/><Area l="Propuesta" value={v.summary} onChange={x=>set('summary',x)}/><Field l="Fuente pública inicial" value={v.evidenceUrl} onChange={x=>set('evidenceUrl',x)}/></div>{msg&&<div className="alert">{msg}</div>}<button disabled={busy} onClick={submit}>{busy?'Registrando…':'Registrar propuesta'}</button>
  </main>;
}
function Field({l,value,onChange,options,type='text',min,max}){return <label><span>{l}</span>{options?<select value={value} onChange={e=>onChange(e.target.value)}><option value="">Seleccione</option>{options.map(x=>typeof x==='string'?<option key={x} value={x}>{x}</option>:<option key={x.value} value={x.value}>{x.label}</option>)}</select>:<input type={type} min={min} max={max} value={value} onChange={e=>onChange(e.target.value)}/>}</label>}
function Area({l,value,onChange}){return <label className="full"><span>{l}</span><textarea rows="5" value={value} onChange={e=>onChange(e.target.value)}/></label>}

function Voting({ballots,auth,setNotice,onRefresh}){
  const[selected,setSelected]=useState(null);const[options,setOptions]=useState([]);const[choice,setChoice]=useState({});const[ranking,setRanking]=useState([]);const[busy,setBusy]=useState(false);
  async function open(b){setSelected(b);setChoice({});setRanking([]);try{setOptions(await getBallotOptions(b.ballot_id));}catch(e){setNotice(e?.message||'No fue posible cargar las opciones.')}}
  async function request(){if(!auth.user)return setNotice('Ingresa para solicitar habilitación.');try{await requestEligibility(selected.ballot_id,'Solicitud desde la plataforma ciudadana');setNotice('Solicitud de habilitación registrada para revisión.');}catch(e){setNotice(e?.message||'No fue posible solicitar habilitación.')}}
  function toggleRank(id){setRanking(r=>r.includes(id)?r.filter(x=>x!==id):[...r,id]);}
  async function vote(){
    if(!auth.user)return setNotice('Ingresa para votar.');let selection;
    if(selected.method==='yes_no')selection={choice:choice.answer||''};
    else if(selected.method==='approval')selection={option_ids:Object.keys(choice).filter(k=>choice[k])};
    else if(selected.method==='points100')selection={points:Object.fromEntries(options.map(o=>[o.id,Number(choice[o.id]||0)]))};
    else if(selected.method==='ranked')selection={ranking};
    else if(selected.method==='participatory_budget')selection={option_ids:Object.keys(choice).filter(k=>choice[k])};
    setBusy(true);try{const receipt=await castVote(selected.ballot_id,selection);setNotice(`Voto registrado. Conserva tu recibo de integridad: ${receipt}`);setSelected(null);await onRefresh();}catch(e){setNotice(e?.message||'No fue posible registrar el voto.');}finally{setBusy(false)}
  }
  const points=options.reduce((s,o)=>s+Number(choice[o.id]||0),0);
  const cost=options.filter(o=>choice[o.id]).reduce((s,o)=>s+Number(o.estimated_cost||0),0);
  const budget=Number(selected?.rules?.budget_total||0);
  return <main><h2>Votaciones y priorización</h2><div className="rulebox"><b>La regla antecede al voto.</b><p>Método, elegibilidad, fechas, opciones y umbrales deben estar congelados antes de abrir una votación.</p></div>
    {!ballots.length&&<div className="card">No hay votaciones abiertas o publicadas en este momento.</div>}
    {ballots.map(b=><article className="proposal" key={b.ballot_id}><div className="tags"><span>{b.status}</span><span>{b.method}</span><span>Integridad: {b.integrity_level}</span></div><h3>{b.title}</h3><div className="metrics">Participantes: {b.participant_count??0} · elegibles: {b.eligible_count??0} · votos: {b.vote_count??0}</div><button onClick={()=>open(b)}>Abrir boleta</button></article>)}
    {selected&&<section className="modalCard"><h3>{selected.title}</h3><p className="muted">Estado: {selected.status}. Tu habilitación y tu selección se procesan separadamente.</p>
      {selected.method==='yes_no'&&<div className="radioGroup">{['yes','no','abstain'].map(x=><label key={x}><input type="radio" name="yn" checked={choice.answer===x} onChange={()=>setChoice({answer:x})}/>{x==='yes'?'Sí':x==='no'?'No':'Abstención'}</label>)}</div>}
      {selected.method==='approval'&&options.map(o=><label className="checkline" key={o.id}><input type="checkbox" checked={!!choice[o.id]} onChange={e=>setChoice({...choice,[o.id]:e.target.checked})}/>{o.label}</label>)}
      {selected.method==='points100'&&<><div className="rulebox">Puntos asignados: <b>{points}/100</b></div>{options.map(o=><label className="vote" key={o.id}><span>{o.label}</span><input type="number" min="0" max="100" value={choice[o.id]||0} onChange={e=>setChoice({...choice,[o.id]:Math.max(0,Math.min(100,Number(e.target.value)||0))})}/><b>{choice[o.id]||0}</b></label>)}</>}
      {selected.method==='ranked'&&<><p>Selecciona opciones en orden de preferencia:</p>{options.map(o=><button className={ranking.includes(o.id)?'ranked selectedRank':'ranked'} key={o.id} onClick={()=>toggleRank(o.id)}>{ranking.includes(o.id)?`${ranking.indexOf(o.id)+1}. `:''}{o.label}</button>)}</>}
      {selected.method==='participatory_budget'&&<><div className="rulebox">Seleccionado: <b>{cost.toLocaleString('es-CO')}</b> de presupuesto <b>{budget.toLocaleString('es-CO')}</b></div>{options.map(o=><label className="checkline" key={o.id}><input type="checkbox" checked={!!choice[o.id]} onChange={e=>setChoice({...choice,[o.id]:e.target.checked})}/>{o.label} {o.estimated_cost!=null&&`· ${Number(o.estimated_cost).toLocaleString('es-CO')}`}</label>)}</>}
      <div className="hero-actions"><button onClick={request}>Solicitar habilitación</button><button disabled={busy||selected.status!=='open'||(selected.method==='points100'&&points!==100)||(selected.method==='participatory_budget'&&budget>0&&cost>budget)} onClick={vote}>{busy?'Registrando…':'Emitir voto'}</button><button className="secondary" onClick={()=>setSelected(null)}>Cerrar</button></div>
    </section>}
  </main>;
}

function Resultados({results,ballots}){return <main><h2>Resultados y trazabilidad</h2><p className="muted">Solo se muestran agregados. El recibo individual sirve para comprobar inclusión técnica, no para revelar públicamente la selección.</p>
  {!results.length&&<div className="card">Aún no existen escrutinios publicados.</div>}
  {results.map(r=>{const b=ballots.find(x=>x.ballot_id===r.ballot_id);return <article className="proposal" key={r.ballot_id}><div className="tags"><span>{r.certification_status}</span><span>{r.method}</span></div><h3>{b?.title||'Resultado de votación'}</h3><p>Participantes: <b>{r.participant_count}</b></p><pre className="resultJson">{JSON.stringify(r.result,null,2)}</pre><div className="hashline">SHA-256: {r.result_hash}</div></article>})}
</main>}

function Cuenta({auth,onRefresh,setNotice}){
  const[email,setEmail]=useState('');const[busy,setBusy]=useState(false);const[code,setCode]=useState('');
  if(auth.user)return <main><h2>Mi cuenta</h2><div className="card"><p><b>{auth.profile?.display_name||auth.user.email}</b></p><p>{auth.user.email}</p><p className="muted">Nivel de verificación: {auth.profile?.verification_level??'pendiente'}</p><div className="tags">{(auth.roles||[]).map(r=><span key={`${r.role}-${r.process_id||r.institution_id||'global'}`}>{r.role}</span>)}</div><button onClick={async()=>{await signOut();await onRefresh();setNotice('Sesión cerrada.')}}>Cerrar sesión</button></div>
    {!(auth.roles||[]).some(r=>r.role==='platform_admin')&&<div className="card sectionGap"><h3>Activación inicial de administración</h3><p className="muted">Solo funciona mientras no exista ningún administrador de plataforma y exige un código de un solo uso entregado por canal seguro.</p><Field l="Código bootstrap" value={code} onChange={setCode}/><button onClick={async()=>{try{await bootstrapPlatformAdmin(code);setCode('');await onRefresh();setNotice('Administración principal activada. El código quedó consumido.');}catch(e){setNotice(e?.message||'No fue posible activar la administración.')}}}>Activar administración</button></div>}
  </main>;
  return <main><h2>Ingresar para participar</h2><div className="card"><p>Usamos acceso sin contraseña por correo. La lectura pública no requiere cuenta.</p><div className="form"><label><span>Correo electrónico</span><input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="tu@correo.com"/></label></div><button disabled={busy} onClick={async()=>{if(!email.includes('@'))return setNotice('Escribe un correo válido.');setBusy(true);const{error}=await signInWithEmail(email);setBusy(false);setNotice(error?error.message:'Revisa tu correo y abre el enlace de acceso.');}}>{busy?'Enviando…':'Enviar enlace de acceso'}</button></div></main>;
}

function AdminConsole({auth,publicData,onRefresh,setNotice}){
  const[tab,setTab]=useState('resumen');const[users,setUsers]=useState([]);const[roles,setRoles]=useState([]);const[pending,setPending]=useState([]);const[processes,setProcesses]=useState([]);const[ballots,setBallots]=useState([]);const[busy,setBusy]=useState(false);
  const platformAdmin=(auth.roles||[]).some(r=>r.role==='platform_admin');
  async function load(){setBusy(true);try{
    const tasks=[adminListProcesses().catch(()=>[]),adminListBallots().catch(()=>[]),adminPendingEligibility().catch(()=>[])];
    if(platformAdmin){tasks.push(adminUserDirectory().catch(()=>[]),adminListGovernanceRoles().catch(()=>[]));}
    const out=await Promise.all(tasks);setProcesses(out[0]);setBallots(out[1]);setPending(out[2]);if(platformAdmin){setUsers(out[3]);setRoles(out[4]);}
  }catch(e){setNotice(e?.message||'No fue posible cargar administración.');}finally{setBusy(false)}}
  useEffect(()=>{load();},[platformAdmin]);
  const tabs=[['resumen','Resumen'],['procesos','Procesos'],['votaciones','Votaciones'],['elegibilidad','Elegibilidad']];if(platformAdmin)tabs.push(['usuarios','Usuarios y roles']);
  return <main><h2>Administración del piloto</h2><div className="rulebox"><b>Separación de poderes internos.</b><p>Los roles de metodología, institución, facilitación, moderación, evaluación, auditoría y custodia de datos son diferenciados. Las operaciones críticas quedan auditadas.</p></div><div className="adminTabs">{tabs.map(([k,t])=><button className={tab===k?'active':''} key={k} onClick={()=>setTab(k)}>{t}</button>)}<button onClick={load}>{busy?'Actualizando…':'Actualizar'}</button></div>
    {tab==='resumen'&&<div className="grid3"><Metric title="Usuarios" n={users.length}/><Metric title="Solicitudes pendientes" n={pending.length}/><Metric title="Votaciones internas" n={ballots.length}/></div>}
    {tab==='usuarios'&&platformAdmin&&<UserAdmin users={users} roles={roles} processes={processes} reload={load} setNotice={setNotice}/>} 
    {tab==='elegibilidad'&&<EligibilityAdmin pending={pending} reload={load} setNotice={setNotice}/>} 
    {tab==='procesos'&&<ProcessAdmin processes={processes} reload={load} setNotice={setNotice}/>} 
    {tab==='votaciones'&&<BallotAdmin ballots={ballots} processes={processes} proposals={publicData.proposals} reload={async()=>{await load();await onRefresh();}} setNotice={setNotice}/>} 
  </main>;
}

function UserAdmin({users,roles,processes,reload,setNotice}){const[selected,setSelected]=useState('');const[role,setRole]=useState('moderator');const[processId,setProcessId]=useState('');return <section className="sectionGap"><h3>Usuarios y responsabilidades</h3><div className="form grid2"><Field l="Usuario" value={selected} onChange={setSelected} options={users.map(u=>({value:u.user_id,label:`${u.display_name||u.email} — ${u.email}`}))}/><Field l="Rol" value={role} onChange={setRole} options={GOV_ROLES}/><Field l="Ámbito de proceso (opcional)" value={processId} onChange={setProcessId} options={processes.map(p=>({value:p.id,label:p.title}))}/></div><button onClick={async()=>{try{await adminAssignRole({userId:selected,role,processId:processId||null});await reload();setNotice('Rol asignado y auditado.');}catch(e){setNotice(e?.message||'No fue posible asignar el rol.')}}}>Asignar rol</button>
  <div className="tableWrap"><table><thead><tr><th>Persona</th><th>Verificación</th><th>Acciones</th></tr></thead><tbody>{users.map(u=><tr key={u.user_id}><td>{u.display_name||'—'}<small>{u.email}</small></td><td>{u.verification_level}</td><td><select value={u.verification_level??1} onChange={async e=>{try{await adminSetVerification(u.user_id,Number(e.target.value));await reload();}catch(err){setNotice(err.message)}}}>{[0,1,2,3,4].map(n=><option key={n}>{n}</option>)}</select></td></tr>)}</tbody></table></div>
  <h4>Roles vigentes e históricos</h4>{roles.map(r=><div className="roleRow" key={r.role_id}><span><b>{r.role}</b> · {r.display_name||r.email} · {r.active?'activo':'revocado'}</span>{r.active&&<button onClick={async()=>{try{await adminRevokeRole(r.role_id);await reload();setNotice('Rol revocado.');}catch(e){setNotice(e.message)}}}>Revocar</button>}</div>)}</section>}

function EligibilityAdmin({pending,reload,setNotice}){return <section className="sectionGap"><h3>Solicitudes de habilitación</h3>{!pending.length&&<div className="card">No hay solicitudes pendientes.</div>}{pending.map(r=><div className="proposal" key={r.request_id}><h4>{r.display_name||r.user_id}</h4><p>{r.ballot_title}</p><p className="muted">Verificación actual: {r.verification_level} · {r.rationale||'Sin justificación adicional'}</p><div className="hero-actions"><button onClick={async()=>{try{await adminDecideEligibility(r.request_id,true,'Aprobada para el piloto');await reload();setNotice('Habilitación aprobada.');}catch(e){setNotice(e.message)}}}>Aprobar</button><button className="danger" onClick={async()=>{try{await adminDecideEligibility(r.request_id,false,'No cumple criterios publicados');await reload();setNotice('Solicitud rechazada.');}catch(e){setNotice(e.message)}}}>Rechazar</button></div></div>)}</section>}

function ProcessAdmin({processes,reload,setNotice}){
  const[v,setV]=useState({title:'',processType:'consulta_ciudadana',legalNature:'consultivo',scopeLevel:'nacional',region:'',department:'',municipality:''});const set=(k,x)=>setV({...v,[k]:x});
  return <section className="sectionGap"><h3>Procesos participativos</h3><div className="form grid2"><Field l="Título" value={v.title} onChange={x=>set('title',x)}/><Field l="Tipo" value={v.processType} onChange={x=>set('processType',x)}/><Field l="Naturaleza jurídica" value={v.legalNature} onChange={x=>set('legalNature',x)} options={['consultivo','priorizacion_participativa','presupuesto_participativo','mecanismo_formal']}/><Field l="Ámbito" value={v.scopeLevel} onChange={x=>set('scopeLevel',x)} options={['nacional','regional','departamental','distrital','municipal','local','institucional']}/><Field l="Región" value={v.region} onChange={x=>set('region',x)}/><Field l="Departamento" value={v.department} onChange={x=>set('department',x)}/><Field l="Municipio" value={v.municipality} onChange={x=>set('municipality',x)}/></div><button onClick={async()=>{try{await adminCreateProcess({...v,rules:{binding_effect:false,methodology:'participación trazable y plural'}});setV({...v,title:''});await reload();setNotice('Proceso creado en borrador.');}catch(e){setNotice(e.message)}}}>Crear proceso</button>
    <div className="sectionGap">{processes.map(p=><article className="proposal" key={p.id}><div className="tags"><span>{p.status}</span><span>{p.legal_nature}</span><span>{p.scope_level}</span></div><h4>{p.title}</h4><label><span>Cambiar etapa</span><select value={p.status} onChange={async e=>{try{await adminSetProcessStatus(p.id,e.target.value);await reload();setNotice('Etapa actualizada.');}catch(err){setNotice(err.message)}}}>{PROCESS_STATUS.map(s=><option key={s}>{s}</option>)}</select></label></article>)}</div>
  </section>;
}

function BallotAdmin({ballots,processes,proposals,reload,setNotice}){
  const[b,setB]=useState({processId:processes[0]?.id||'',title:'',method:'approval',verificationRequired:1,integrityLevel:'pilot'});const[option,setOption]=useState({ballotId:'',label:'',proposalId:'',estimatedCost:''});const[consensus,setConsensus]=useState({processId:processes[0]?.id||'',minParticipants:'',minTurnoutPct:'',minSupportPct:'',minTerritories:'',minTerritorySupportPct:''});
  useEffect(()=>{if(!b.processId&&processes[0])setB(x=>({...x,processId:processes[0].id}));if(!consensus.processId&&processes[0])setConsensus(x=>({...x,processId:processes[0].id}));},[processes]);
  return <section className="sectionGap"><h3>Diseñar votaciones</h3><div className="grid2"><div className="card"><h4>1. Criterios de resultado/consenso</h4><div className="form"><Field l="Proceso" value={consensus.processId} onChange={x=>setConsensus({...consensus,processId:x})} options={processes.map(p=>({value:p.id,label:p.title}))}/><Field l="Participantes mínimos" type="number" value={consensus.minParticipants} onChange={x=>setConsensus({...consensus,minParticipants:x})}/><Field l="Apoyo mínimo %" type="number" value={consensus.minSupportPct} onChange={x=>setConsensus({...consensus,minSupportPct:x})}/><Field l="Territorios mínimos" type="number" value={consensus.minTerritories} onChange={x=>setConsensus({...consensus,minTerritories:x})}/></div><button onClick={async()=>{try{await adminPublishConsensusRules({...consensus,minParticipants:Number(consensus.minParticipants)||null,minSupportPct:Number(consensus.minSupportPct)||null,minTerritories:Number(consensus.minTerritories)||null});setNotice('Criterios publicados con hash.');}catch(e){setNotice(e.message)}}}>Publicar criterios</button></div>
    <div className="card"><h4>2. Crear votación</h4><div className="form"><Field l="Proceso" value={b.processId} onChange={x=>setB({...b,processId:x})} options={processes.map(p=>({value:p.id,label:p.title}))}/><Field l="Título" value={b.title} onChange={x=>setB({...b,title:x})}/><Field l="Método" value={b.method} onChange={x=>setB({...b,method:x})} options={['approval','points100','yes_no','ranked','participatory_budget']}/><Field l="Verificación requerida" type="number" min="1" max="4" value={b.verificationRequired} onChange={x=>setB({...b,verificationRequired:Number(x)})}/><Field l="Nivel de integridad" value={b.integrityLevel} onChange={x=>setB({...b,integrityLevel:x})} options={['pilot','enhanced','independent_audit','formal_mechanism']}/></div><button onClick={async()=>{try{const rules=b.method==='ranked'?{ranked_tally:'borda'}:b.method==='participatory_budget'?{budget_total:1000000000}:{};await adminCreateBallot({...b,rules});setB({...b,title:''});await reload();setNotice('Votación creada en borrador.');}catch(e){setNotice(e.message)}}}>Crear votación</button></div></div>
    <div className="card sectionGap"><h4>3. Añadir opciones</h4><div className="form grid2"><Field l="Votación" value={option.ballotId} onChange={x=>setOption({...option,ballotId:x})} options={ballots.filter(x=>x.status==='draft').map(x=>({value:x.id,label:x.title}))}/><Field l="Etiqueta" value={option.label} onChange={x=>setOption({...option,label:x})}/><Field l="Propuesta vinculada" value={option.proposalId} onChange={x=>setOption({...option,proposalId:x})} options={proposals.map(p=>({value:p.id,label:p.title}))}/><Field l="Costo estimado (presupuesto participativo)" type="number" value={option.estimatedCost} onChange={x=>setOption({...option,estimatedCost:x})}/></div><button onClick={async()=>{try{await adminAddBallotOption({...option,estimatedCost:option.estimatedCost?Number(option.estimatedCost):null});setOption({...option,label:'',proposalId:'',estimatedCost:''});await reload();setNotice('Opción añadida.');}catch(e){setNotice(e.message)}}}>Añadir opción</button></div>
    <h4 className="sectionGap">4. Abrir, cerrar y certificar</h4>{ballots.map(x=><BallotControl key={x.id} ballot={x} reload={reload} setNotice={setNotice}/>)}</section>;
}
function BallotControl({ballot,reload,setNotice}){const[opens,setOpens]=useState('');const[closes,setCloses]=useState('');return <article className="proposal"><div className="tags"><span>{ballot.status}</span><span>{ballot.method}</span><span>{ballot.integrity_level}</span></div><h4>{ballot.title}</h4>{ballot.status==='draft'&&<div className="form grid2"><Field l="Apertura" type="datetime-local" value={opens} onChange={setOpens}/><Field l="Cierre" type="datetime-local" value={closes} onChange={setCloses}/></div>}<div className="hero-actions">{ballot.status==='draft'&&<button onClick={async()=>{try{await adminOpenBallot({ballotId:ballot.id,opensAt:new Date(opens).toISOString(),closesAt:new Date(closes).toISOString()});await reload();setNotice('Reglas y opciones congeladas; votación abierta.');}catch(e){setNotice(e.message)}}}>Congelar y abrir</button>}{ballot.status==='open'&&<button onClick={async()=>{try{await adminCloseAndTally(ballot.id,'Escrutinio automatizado del método previamente congelado');await reload();setNotice('Votación cerrada y resultado agregado calculado.');}catch(e){setNotice(e.message)}}}>Cerrar y escrutar</button>}{ballot.status==='closed'&&<button onClick={async()=>{try{await adminCertifyBallot(ballot.id,'Certificación administrativa del piloto');await reload();setNotice('Resultado certificado y hash preservado.');}catch(e){setNotice(e.message)}}}>Certificar</button>}</div></article>}

function Metodo(){return <main><h2>Reglas de legitimidad</h2><div className="grid2"><Card title="Igualdad política" text="La profesión, el patrimonio, el cargo o el conocimiento técnico no multiplican el voto de una persona."/><Card title="Reglas congeladas" text="Método, universo, opciones, fechas, umbrales y desempates se publican antes de abrir la votación."/><Card title="Deliberación informada" text="Argumentos a favor, en contra, alternativas, preguntas, enmiendas y evidencia quedan diferenciados."/><Card title="Evaluación técnica separada" text="Expertos analizan viabilidad jurídica, fiscal, ambiental, social y operativa sin alterar el peso democrático."/><Card title="Transparencia verificable" text="Versiones, reglas, resultados e hitos críticos generan hashes y pueden anclarse externamente sin publicar datos personales."/><Card title="Privacidad y secreto" text="Identidad, elegibilidad y selección se separan. Nunca se publica PII o voto individual en blockchain."/><Card title="IA subordinada" text="Puede ayudar a resumir, traducir, agrupar y detectar señales de abuso; no decide ganadores ni elimina posiciones por criterio ideológico."/><Card title="Naturaleza jurídica visible" text="Cada resultado indica si es consultivo, una prioridad participativa o parte de un mecanismo formalmente vinculante."/></div></main>}
