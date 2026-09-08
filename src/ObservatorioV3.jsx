import React, { useEffect, useMemo, useState } from "react";
import {
  backendMode,
  getAuthContext,
  loadState,
  onAuthChange,
  resolveReport,
  signInWithEmail,
  signOut,
  submitReport,
  upsertFinding,
} from "./lib/store.js";
import { supabase } from "./lib/supabase.js";

const NIVELES = ["nacional", "departamental", "distrital", "municipal", "regional"];
const REGIONES = ["Andina", "Caribe", "Pacífica", "Orinoquía", "Amazonía", "Insular", "Interregional"];
const DEPTOS = ["Amazonas","Antioquia","Arauca","Atlántico","Bogotá D.C.","Bolívar","Boyacá","Caldas","Caquetá","Casanare","Cauca","Cesar","Chocó","Córdoba","Cundinamarca","Guainía","Guaviare","Huila","La Guajira","Magdalena","Meta","Nariño","Norte de Santander","Putumayo","Quindío","Risaralda","San Andrés y Providencia","Santander","Sucre","Tolima","Valle del Cauca","Vaupés","Vichada"];
const CLASES = {
  legalidad: { t: "Defecto jurídico", c: "red" },
  integridad: { t: "Riesgo de integridad", c: "ochre" },
  conforme: { t: "Conforme a derecho", c: "green" },
};
const VERIF = { documentado: "DOCUMENTADO", verificacion: "EN VERIFICACIÓN", sinverificar: "SIN VERIFICAR" };
const hoy = () => new Date().toISOString().slice(0, 10);
const territorio = f => f.nivel === "nacional" ? "Nacional" : [f.nivel, f.region, f.departamento, f.municipio, f.territorio].filter(Boolean).join(" · ");

export default function ObservatorioV3() {
  const [vista, setVista] = useState("tablero");
  const [fichas, setFichas] = useState([]);
  const [reportes, setReportes] = useState([]);
  const [auth, setAuth] = useState({ user: null, profile: null, roles: [], canCurate: false });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [deadlines, setDeadlines] = useState([]);

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      const [state, ctx] = await Promise.all([loadState(), getAuthContext()]);
      setFichas(state.fichas || []);
      setReportes(state.reportes || []);
      setAuth(ctx);
      if (ctx.canCurate && supabase) {
        const { data } = await supabase.from("pending_deadlines").select("*").order("due_at", { ascending: true });
        setDeadlines(data || []);
      } else setDeadlines([]);
    } catch (e) {
      setError(e?.message || "No fue posible cargar la plataforma.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    const off = onAuthChange(refresh);
    return off;
  }, []);

  async function handleSubmit(r) {
    setError("");
    try {
      const id = await submitReport(r);
      alert(id ? `Reporte recibido. Identificador: ${id}` : "Reporte recibido.");
      await refresh();
      setVista("tablero");
    } catch (e) {
      setError(e?.message || "No fue posible enviar el reporte.");
    }
  }

  async function promote(r) {
    try {
      await resolveReport(r, {
        ...r,
        clase: r.clase || "integridad",
        verificacion: "verificacion",
        replica: "no_notificado",
      });
      await refresh();
    } catch (e) { setError(e?.message || "No fue posible promover el reporte."); }
  }

  async function discard(r) {
    try { await resolveReport(r, null); await refresh(); }
    catch (e) { setError(e?.message || "No fue posible descartar el reporte."); }
  }

  async function saveFinding(f) {
    try { await upsertFinding(f); await refresh(); }
    catch (e) { setError(e?.message || "No fue posible guardar la ficha."); }
  }

  return <div className="app">
    <header className="header"><div className="wrap">
      <div className="rot">Veeduría ciudadana · Ley 850 de 2003</div>
      <h1>Observatorio Ciudadano de Legalidad y Transparencia</h1>
      <div className="mono small muted">Vigilancia nacional, departamental, distrital, municipal y regional · Colombia</div>
    </div></header>
    <div className="wrap">
      <div className="warning" style={{marginTop:14}}>
        Datos compartidos mediante backend seguro. Las fichas públicas siguen sujetas a verificación humana, fuente primaria y derecho de réplica.
      </div>
      {error && <div className="warning" style={{marginTop:10}}>{error}</div>}
      <nav className="nav">
        {[["tablero","Tablero"],["registro","Registro"],["reportar","Reportar"],["curaduria",`Curaduría${auth.canCurate ? ` (${reportes.length})` : ""}`],["boletin","Boletín"],["metodo","Metodología"]].map(([k,t]) => <button key={k} className={vista===k?"active":""} onClick={()=>setVista(k)}>{t}</button>)}
      </nav>
      <main className="main">
        {loading && <div className="card">Cargando información…</div>}
        {!loading && vista==="tablero" && <Tablero fichas={fichas} deadlines={deadlines}/>} 
        {!loading && vista==="registro" && <Registro fichas={fichas} auth={auth} onSave={saveFinding}/>} 
        {!loading && vista==="reportar" && <Reportar onEnviar={handleSubmit}/>} 
        {!loading && vista==="curaduria" && <Curaduria auth={auth} reportes={reportes} onPromote={promote} onDiscard={discard} onRefresh={refresh}/>} 
        {!loading && vista==="boletin" && <Boletin fichas={fichas}/>} 
        {!loading && vista==="metodo" && <Metodo/>}
      </main>
    </div>
    <footer className="footer"><div className="wrap">El Observatorio documenta y contrasta actuaciones institucionales. No declara nulidades ni responsabilidades. Modo de datos: {backendMode()==="supabase"?"base compartida":"local"}.</div></footer>
  </div>;
}

function Tablero({ fichas, deadlines }) {
  const c = k => fichas.filter(f=>f.clase===k).length;
  const nat = fichas.filter(f=>f.nivel==="nacional").length;
  const ter = fichas.length - nat;
  const vencidos = deadlines.filter(x=>x.due_at && new Date(x.due_at)<new Date()).length;
  return <><h2>Tablero de cobertura</h2><p className="muted">Cobertura nacional y territorial bajo un estándar uniforme de verificación.</p><div className="grid cards">
    <Card t="Fichas visibles" n={fichas.length}/><Card t="Nacionales" n={nat}/><Card t="Territoriales/regionales" n={ter}/><Card t="Defectos jurídicos" n={c("legalidad")}/><Card t="Riesgos de integridad" n={c("integridad")}/><Card t="Conformes a derecho" n={c("conforme")}/><Card t="Vencimientos internos" n={vencidos}/>
  </div>{deadlines.length>0&&<><h3>Próximos vencimientos internos</h3>{deadlines.slice(0,8).map(x=><div className="item" key={`${x.item_type}-${x.id}`}><b>{x.item_type}</b> · {x.counterparty}<div className="small muted">Vence: {x.due_at?new Date(x.due_at).toLocaleString("es-CO"):"—"} · Estado: {x.status}</div></div>)}</>}</>;
}
const Card = ({t,n}) => <div className="card"><div className="rot">{t}</div><div className="big mono">{n}</div></div>;

function Registro({ fichas, auth, onSave }) {
  const [amb,setAmb]=useState("todos"), [reg,setReg]=useState("todas"), [dep,setDep]=useState("todos");
  const lista = useMemo(()=>fichas.filter(f=>(amb==="todos"||(amb==="nacional"?f.nivel==="nacional":f.nivel!=="nacional"))&&(reg==="todas"||f.region===reg)&&(dep==="todos"||f.departamento===dep)),[fichas,amb,reg,dep]);
  return <><h2>Registro</h2><div className="grid filters"><select className="campo" value={amb} onChange={e=>setAmb(e.target.value)}><option value="todos">Todos los ámbitos</option><option value="nacional">Nacional</option><option value="territorial">Territorial / regional</option></select><select className="campo" value={reg} onChange={e=>setReg(e.target.value)}><option value="todas">Todas las regiones</option>{REGIONES.map(x=><option key={x}>{x}</option>)}</select><select className="campo" value={dep} onChange={e=>setDep(e.target.value)}><option value="todos">Todos los departamentos</option>{DEPTOS.map(x=><option key={x}>{x}</option>)}</select></div>{!lista.length&&<div className="card">No hay fichas para este filtro.</div>}{lista.map(f=><Ficha key={f.id||f.folio} f={f} canCurate={auth.canCurate} onSave={onSave}/>)}</>;
}

function Ficha({f,canCurate,onSave}) {
  const [replica,setReplica]=useState(f.replica||"no_notificado"), [verificacion,setVerificacion]=useState(f.verificacion||"sinverificar");
  return <article className="item"><div className="row"><span className={`badge ${CLASES[f.clase]?.c||"red"}`}>{CLASES[f.clase]?.t||f.clase}</span><span className={`badge ${verificacion==="documentado"?"green":verificacion==="verificacion"?"ochre":"red"}`}>{VERIF[verificacion]||verificacion}</span><span className="mono small">F.{String(f.folio||0).padStart(4,"0")}</span></div><h3>{f.actoTipo} {f.actoId}</h3><div className="meta small muted">{f.entidad} · {f.fecha||"s/f"} · {territorio(f)}</div><p>{f.hecho}</p>{f.norma&&<div className="small"><b>Norma de contraste:</b> {f.norma}</div>}{f.fuente&&<div className="small"><b>Soporte:</b> {f.fuente}</div>}{canCurate&&<div className="grid form" style={{marginTop:12}}><label><span className="rot">Verificación</span><select className="campo" value={verificacion} onChange={e=>setVerificacion(e.target.value)}><option value="sinverificar">Sin verificar</option><option value="verificacion">En verificación</option><option value="documentado">Documentado</option></select></label><label><span className="rot">Réplica</span><select className="campo" value={replica} onChange={e=>setReplica(e.target.value)}><option value="no_notificado">Sin notificar</option><option value="notificado">Notificada</option><option value="respondido">Respondida</option><option value="no_aplica">No aplica</option></select></label><div><button className="btn" onClick={()=>onSave({...f,verificacion,replica,publicado:verificacion==="documentado"&&replica!=="no_notificado"})}>Guardar estado</button></div></div>}</article>;
}

function Reportar({onEnviar}) {
  const [v,setV]=useState({nivel:"nacional",region:"",departamento:"",municipio:"",territorio:"",entidad:"",actoTipo:"Decreto",actoId:"",fecha:hoy(),clase:"legalidad",hecho:"",norma:"",fuente:"",contacto:"",veraz:false});
  const set=(k,x)=>setV({...v,[k]:x});
  const enviar=()=>{if(!v.entidad||!v.actoId||v.hecho.trim().length<40||!v.fuente||!v.veraz||(v.clase==="legalidad"&&!v.norma))return alert("Complete entidad, acto, relato mínimo de 40 caracteres, soporte, norma cuando corresponda y declaración de veracidad.");onEnviar(v)};
  return <><h2>Reportar una actuación</h2><div className="warning">El reporte no se publica automáticamente. Entra a curaduría y verificación documental.</div><div className="grid form"><label><span className="rot">Nivel</span><select className="campo" value={v.nivel} onChange={e=>set("nivel",e.target.value)}>{NIVELES.map(x=><option key={x}>{x}</option>)}</select></label>{v.nivel!=="nacional"&&<><label><span className="rot">Región</span><select className="campo" value={v.region} onChange={e=>set("region",e.target.value)}><option value="">Seleccione</option>{REGIONES.map(x=><option key={x}>{x}</option>)}</select></label><label><span className="rot">Departamento</span><select className="campo" value={v.departamento} onChange={e=>set("departamento",e.target.value)}><option value="">Seleccione</option>{DEPTOS.map(x=><option key={x}>{x}</option>)}</select></label><label><span className="rot">Municipio/Distrito</span><input className="campo" value={v.municipio} onChange={e=>set("municipio",e.target.value)}/></label><label><span className="rot">Territorio/Jurisdicción</span><input className="campo" value={v.territorio} onChange={e=>set("territorio",e.target.value)}/></label></>}<label><span className="rot">Entidad</span><input className="campo" value={v.entidad} onChange={e=>set("entidad",e.target.value)}/></label><label><span className="rot">Tipo de actuación</span><input className="campo" value={v.actoTipo} onChange={e=>set("actoTipo",e.target.value)}/></label><label><span className="rot">Identificación</span><input className="campo" value={v.actoId} onChange={e=>set("actoId",e.target.value)}/></label><label><span className="rot">Fecha</span><input type="date" className="campo" value={v.fecha} onChange={e=>set("fecha",e.target.value)}/></label><label><span className="rot">Clase</span><select className="campo" value={v.clase} onChange={e=>set("clase",e.target.value)}>{Object.entries(CLASES).map(([k,x])=><option key={k} value={k}>{x.t}</option>)}</select></label><label className="full"><span className="rot">Relato verificable</span><textarea className="campo" rows="5" value={v.hecho} onChange={e=>set("hecho",e.target.value)}/></label><label className="full"><span className="rot">Norma de contraste</span><input className="campo" value={v.norma} onChange={e=>set("norma",e.target.value)}/></label><label className="full"><span className="rot">Fuente / URL</span><input className="campo" value={v.fuente} onChange={e=>set("fuente",e.target.value)}/></label><label className="full"><span className="rot">Contacto privado opcional</span><input className="campo" value={v.contacto} onChange={e=>set("contacto",e.target.value)} placeholder="Correo o teléfono; no se publica"/></label><label className="full"><input type="checkbox" checked={v.veraz} onChange={e=>set("veraz",e.target.checked)}/> Declaro que la información se suministra de buena fe y puede ser sometida a verificación.</label><div><button className="btn" onClick={enviar}>Enviar a curaduría</button></div></div></>;
}

function Curaduria({auth,reportes,onPromote,onDiscard,onRefresh}) {
  const [email,setEmail]=useState(""), [msg,setMsg]=useState("");
  if(!auth.user) return <><h2>Curaduría interna</h2><div className="card"><p>Acceso restringido al equipo autorizado.</p><input className="campo" type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="correo autorizado"/><button className="btn" onClick={async()=>{const {error}=await signInWithEmail(email);setMsg(error?error.message:"Enlace de acceso enviado al correo.")}}>Enviar enlace de acceso</button>{msg&&<p className="small muted">{msg}</p>}</div></>;
  return <><div className="row"><h2 style={{flex:1}}>Curaduría</h2><button className="btn" onClick={async()=>{await signOut();await onRefresh()}}>Cerrar sesión</button></div><div className="small muted">{auth.profile?.display_name||auth.user.email} · {auth.profile?.global_role||"rol territorial"}</div>{!auth.canCurate&&<div className="warning">La cuenta existe, pero todavía no tiene rol de curaduría asignado.</div>}{auth.canCurate&&!reportes.length&&<div className="card">No hay reportes pendientes en su ámbito.</div>}{auth.canCurate&&reportes.map(r=><article className="item" key={r.id}><div className="row"><span className={`badge ${CLASES[r.clase]?.c||"ochre"}`}>{CLASES[r.clase]?.t||r.clase||"Sin clasificar"}</span><span className="mono small">{territorio(r)}</span></div><h3>{r.actoTipo} {r.actoId}</h3><div className="small muted">{r.entidad} · recibido {r.recibido}</div><p>{r.hecho}</p>{r.contacto&&<div className="small"><b>Contacto privado:</b> {r.contacto}</div>}<div className="row"><button className="btn" onClick={()=>onPromote(r)}>Promover a ficha</button><button className="btn" onClick={()=>onDiscard(r)}>Descartar</button></div></article>)}</>;
}

function Boletin({fichas}) { const docs=fichas.filter(f=>f.verificacion==="documentado"); return <><h2>Boletín</h2><p className="muted">Solo incluye fichas documentadas visibles para consulta.</p>{!docs.length&&<div className="card">Aún no hay fichas documentadas.</div>}{docs.map(f=><div className="item" key={f.id}><b>{f.actoTipo} {f.actoId}</b> — {f.entidad}<div className="small muted">{territorio(f)}</div></div>)}</>; }

function Metodo(){return <><h2>Metodología</h2><div className="card"><p><b>1. Identificación.</b> Acto, entidad, fecha, nivel territorial y soporte.</p><p><b>2. Contraste.</b> Norma concreta o indicador de integridad.</p><p><b>3. Verificación.</b> La etiqueta DOCUMENTADO exige soporte primario verificable.</p><p><b>4. Réplica.</b> La entidad involucrada debe tener oportunidad de respuesta antes de publicación definitiva.</p><p><b>5. Competencia.</b> Los traslados se orientan según nivel, sujeto, materia y autoridad competente.</p><p><b>6. Trazabilidad.</b> Reportes, cambios y actuaciones internas quedan separados de la vista pública y sujetos a control por roles.</p></div></>}
