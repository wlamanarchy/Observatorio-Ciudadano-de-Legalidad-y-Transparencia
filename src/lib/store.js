import { supabase, supabaseEnabled } from "./supabase.js";

const STORAGE_KEY = "oclt:registro-v3";
const LEGACY_STORAGE_KEY = "oclt:registro-v2";

function normalizar(item = {}) {
  const nivel = item.nivel || "nacional";
  return {
    nivel,
    region: item.region || (nivel === "nacional" ? "Nacional" : ""),
    departamento: item.departamento || "",
    municipio: item.municipio || "",
    territorio: item.territorio || "",
    ambitoTipo: item.ambitoTipo || item.scope_type_code || nivel,
    ambitoNombre: item.ambitoNombre || item.scope_name || item.territorio || "",
    entidadTipo: item.entidadTipo || item.entity_type_code || "",
    materia: item.materia || item.subject_matter || "",
    impacto: item.impacto || item.impact_level || "medio",
    rutaControl: item.rutaControl || item.control_route_code || "",
    ...item,
  };
}

function localRead(key) {
  const value = window.localStorage?.getItem(key);
  if (!value) throw new Error("sin datos");
  return value;
}

export function backendMode() { return supabaseEnabled ? "supabase" : "local"; }

export async function getAuthContext() {
  if (!supabaseEnabled) {
    return { user:{id:"local-demo",email:"demo@local"}, profile:{global_role:"admin_nacional",display_name:"Modo local"}, roles:[{role:"admin_nacional",region:null,department:null}], canCurate:true };
  }
  const { data:{session} } = await supabase.auth.getSession();
  if (!session?.user) return { user:null, profile:null, roles:[], canCurate:false };
  const [profileRes,rolesRes] = await Promise.all([
    supabase.from("profiles").select("*").eq("id",session.user.id).maybeSingle(),
    supabase.from("territorial_roles").select("*").eq("user_id",session.user.id).eq("active",true),
  ]);
  const profile=profileRes.data||null, roles=rolesRes.data||[];
  const canCurate=["admin_nacional","curador_nacional"].includes(profile?.global_role)||roles.length>0;
  return { user:session.user, profile, roles, canCurate };
}

export function onAuthChange(callback){
  if(!supabaseEnabled)return()=>{};
  const {data}=supabase.auth.onAuthStateChange(()=>callback());
  return()=>data.subscription.unsubscribe();
}

export async function signInWithEmail(email){
  if(!supabaseEnabled)return{error:new Error("Supabase no está configurado")};
  return supabase.auth.signInWithOtp({email,options:{emailRedirectTo:window.location.href.split("#")[0].split("?")[0]}});
}
export async function signOut(){if(supabaseEnabled)await supabase.auth.signOut();}

function rowToFinding(row){
  const payload=normalizar(row.payload||{});
  return {...payload,id:row.id,folio:row.folio??payload.folio,nivel:row.level||payload.nivel,region:row.region||payload.region,departamento:row.department||payload.departamento,municipio:row.municipality||payload.municipio,territorio:row.territory||payload.territorio,entidad:row.entity_name||payload.entidad,actoTipo:row.act_type||payload.actoTipo,actoId:row.act_id||payload.actoId,fecha:row.act_date||payload.fecha,clase:row.finding_class||payload.clase,verificacion:row.verification_status||payload.verificacion,replica:row.replica_status||payload.replica,publicado:Boolean(row.published),ambitoTipo:row.scope_type_code||payload.ambitoTipo,ambitoNombre:row.scope_name||payload.ambitoNombre,entidadTipo:row.entity_type_code||payload.entidadTipo,materia:row.subject_matter||payload.materia,impacto:row.impact_level||payload.impacto,rutaControl:row.control_route_code||payload.rutaControl};
}

function rowToReport(row){
  return normalizar({...(row.payload||{}),id:row.id,recibido:row.received_at?.slice?.(0,10)||row.payload?.recibido,nivel:row.level||row.payload?.nivel,region:row.region||row.payload?.region,departamento:row.department||row.payload?.departamento,municipio:row.municipality||row.payload?.municipio,territorio:row.territory||row.payload?.territorio,entidad:row.entity_name||row.payload?.entidad,actoTipo:row.act_type||row.payload?.actoTipo,actoId:row.act_id||row.payload?.actoId,fecha:row.act_date||row.payload?.fecha,clase:row.class_hint||row.payload?.clase,estadoInterno:row.status,contacto:row.reporter_private?.[0]?.contact||row.reporter_private?.contact||"",ambitoTipo:row.scope_type_code||row.payload?.ambitoTipo,ambitoNombre:row.scope_name||row.payload?.ambitoNombre,entidadTipo:row.entity_type_code||row.payload?.entidadTipo,materia:row.subject_matter||row.payload?.materia,impacto:row.impact_level||row.payload?.impacto,rutaControl:row.control_route_code||row.payload?.rutaControl});
}

export async function loadState(){
  if(!supabaseEnabled){
    let parsed;try{parsed=JSON.parse(localRead(STORAGE_KEY));}catch{try{parsed=JSON.parse(localRead(LEGACY_STORAGE_KEY));}catch{parsed={fichas:[],reportes:[]};}}
    return{fichas:(parsed.fichas||[]).map(normalizar),reportes:(parsed.reportes||[]).map(normalizar)};
  }
  const [{data:findings,error:findingsError},auth]=await Promise.all([supabase.from("findings").select("*").order("folio",{ascending:false}),getAuthContext()]);
  if(findingsError)throw findingsError;
  let reportes=[];
  if(auth.canCurate){
    const {data,error}=await supabase.from("reports").select("*, reporter_private(contact)").in("status",["received","triage","verification"]).order("received_at",{ascending:false});
    if(error)throw error;reportes=(data||[]).map(rowToReport);
  }
  return{fichas:(findings||[]).map(rowToFinding),reportes};
}

export async function saveLocalState(state){window.localStorage?.setItem(STORAGE_KEY,JSON.stringify(state));}

export async function upsertFinding(f){
  if(!supabaseEnabled)return;
  const row={id:f.id,level:f.nivel||"nacional",region:f.region||null,department:f.departamento||null,municipality:f.municipio||null,territory:f.territorio||null,entity_name:f.entidad||"",act_type:f.actoTipo||"",act_id:f.actoId||"",act_date:f.fecha||null,finding_class:f.clase||"integridad",verification_status:f.verificacion||"sinverificar",replica_status:f.replica||"no_notificado",published:Boolean(f.publicado),payload:f};
  const {error}=await supabase.from("findings").upsert(row,{onConflict:"id"});if(error)throw error;
}

export async function submitReport(report){
  if(!supabaseEnabled)return null;
  const {contacto="",...publicReport}=report;
  const {data,error}=await supabase.rpc("submit_report",{p_report:publicReport,p_contact:contacto||null});if(error)throw error;return data;
}

export async function resolveReport(report,finding){
  if(!supabaseEnabled)return;
  const {error}=await supabase.rpc("resolve_report",{p_report_id:report.id,p_finding:finding||null,p_outcome:finding?"promoted":"discarded"});if(error)throw error;
}

export async function loadCaseDetail(findingId,canCurate=false){
  if(!supabaseEnabled)return{sources:[],replicas:[],transfers:[],events:[]};
  const tasks=[supabase.from("sources").select("*").eq("finding_id",findingId).order("created_at",{ascending:false})];
  if(canCurate){tasks.push(supabase.from("replicas").select("*").eq("finding_id",findingId).order("created_at",{ascending:false}),supabase.from("transfers").select("*").eq("finding_id",findingId).order("created_at",{ascending:false}),supabase.from("case_events").select("*").eq("finding_id",findingId).order("created_at",{ascending:false}));}
  const out=await Promise.all(tasks);for(const r of out)if(r.error)throw r.error;
  return{sources:out[0]?.data||[],replicas:canCurate?(out[1]?.data||[]):[],transfers:canCurate?(out[2]?.data||[]):[],events:canCurate?(out[3]?.data||[]):[]};
}

export async function addCaseSource({findingId,title,url,reference,isPrimary=false,isPublic=true,verified=false,userId}){
  const row={finding_id:findingId,source_type:isPrimary?"fuente_primaria":"fuente_complementaria",title:title||null,url:url||null,reference:reference||null,is_primary:isPrimary,is_public:isPublic,verified,created_by:userId||null,verified_by:verified?(userId||null):null,verified_at:verified?new Date().toISOString():null};
  const {error}=await supabase.from("sources").insert(row);if(error)throw error;
}
export async function addReplica({findingId,recipient,dueAt,filingId,userId}){
  const now=new Date().toISOString();const {error}=await supabase.from("replicas").insert({finding_id:findingId,recipient,sent_at:now,due_at:dueAt||null,filing_id:filingId||null,status:"enviado",created_by:userId||null,updated_by:userId||null});if(error)throw error;
}
export async function addTransfer({findingId,authority,transferType="traslado",dueAt,filingId,userId}){
  const now=new Date().toISOString();const {error}=await supabase.from("transfers").insert({finding_id:findingId,authority,transfer_type:transferType,sent_at:now,due_at:dueAt||null,filing_id:filingId||null,status:filingId?"radicado":"pendiente",created_by:userId||null,updated_by:userId||null});if(error)throw error;
}
