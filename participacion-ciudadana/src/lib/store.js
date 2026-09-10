import { supabase, supabaseEnabled } from './supabase.js';

const demo = {
  processes: [
    { id: 'demo-process', title: 'Visión Colombia 2050 — piloto', process_type: 'vision_largo_plazo', legal_nature: 'consultivo', scope_level: 'nacional', status: 'deliberation' }
  ],
  proposals: [
    { id:'d1',process_id:'demo-process',title:'Universidad pública regional y formación pertinente',summary:'Fortalecer oferta universitaria conectada con vocaciones productivas, científicas y sociales del territorio.',problem:'Persisten brechas territoriales de acceso y pertinencia de la educación superior que limitan capacidades regionales.',expected_outcome:'Mayor cobertura y pertinencia territorial.',theme:'Educación',scope_level:'Regional',status:'deliberation',contribution_count:24,created_at:new Date().toISOString() },
    { id:'d2',process_id:'demo-process',title:'Plan nacional de agua y resiliencia climática',summary:'Priorizar abastecimiento, saneamiento, protección de cuencas y adaptación climática con metas verificables.',problem:'Múltiples territorios enfrentan riesgos de abastecimiento, deterioro de cuencas y vulnerabilidad climática.',expected_outcome:'Seguridad hídrica medible y resiliencia territorial.',theme:'Agua',scope_level:'Nacional',status:'evaluation',contribution_count:41,created_at:new Date().toISOString() },
    { id:'d3',process_id:'demo-process',title:'Red de innovación y bioeconomía territorial',summary:'Articular universidades, comunidades, empresas y Estado alrededor de proyectos de innovación con impacto regional.',problem:'Las capacidades científicas y productivas se encuentran fragmentadas y con baja articulación en varios territorios.',expected_outcome:'Ecosistemas regionales de innovación con resultados verificables.',theme:'Ciencia y tecnología',scope_level:'Departamental',status:'eligible',contribution_count:33,created_at:new Date().toISOString() }
  ],
  diagnostics: [],
  ballots: []
};

export const backendMode = () => supabaseEnabled ? 'supabase' : 'demo';

export async function getSession(){
  if(!supabase) return { user:null, profile:null };
  const { data:{ session }, error } = await supabase.auth.getSession();
  if(error) throw error;
  if(!session?.user) return { user:null, profile:null };
  const { data:profile } = await supabase.from('citizen_profiles').select('*').eq('id',session.user.id).maybeSingle();
  return { user:session.user, profile:profile||null };
}

export function onAuthChange(callback){
  if(!supabase) return () => {};
  const { data } = supabase.auth.onAuthStateChange(async (_event, session) => {
    let profile=null;
    if(session?.user){
      const res=await supabase.from('citizen_profiles').select('*').eq('id',session.user.id).maybeSingle();
      profile=res.data||null;
    }
    callback({user:session?.user||null,profile});
  });
  return () => data.subscription.unsubscribe();
}

export async function signInWithEmail(email){
  if(!supabase) throw new Error('El backend del piloto aún no está configurado.');
  return supabase.auth.signInWithOtp({
    email,
    options:{ emailRedirectTo: window.location.href.split('#')[0].split('?')[0] }
  });
}

export async function signOut(){
  if(!supabase) return;
  const { error }=await supabase.auth.signOut();
  if(error) throw error;
}

export async function listProcesses(){
  if(!supabase) return demo.processes;
  const { data,error }=await supabase.from('public_process_directory').select('*').order('created_at',{ascending:false});
  if(error) throw error;
  return data||[];
}

export async function listDiagnostics(){
  if(!supabase) return demo.diagnostics;
  const { data,error }=await supabase.from('diagnostics').select('id,process_id,title,description,baseline,source_url,observatory_reference,created_at').order('created_at',{ascending:false});
  if(error) throw error;
  return data||[];
}

export async function listProposals(){
  if(!supabase) return demo.proposals;
  const { data,error }=await supabase.from('public_proposal_feed').select('*').order('created_at',{ascending:false});
  if(error) throw error;
  return data||[];
}

export async function listContributions(proposalId){
  if(!supabase) return [];
  const { data,error }=await supabase.from('contributions').select('id,proposal_id,contribution_type,body,source_url,status,created_at').eq('proposal_id',proposalId).eq('status','visible').order('created_at',{ascending:true});
  if(error) throw error;
  return data||[];
}

export async function createProposal(input){
  if(!supabase) throw new Error('Para registrar propuestas reales debes ingresar a un piloto conectado.');
  const { data,error }=await supabase.rpc('submit_citizen_proposal',{
    p_process_id:input.processId,
    p_title:input.title,
    p_summary:input.summary,
    p_problem:input.problem,
    p_expected_outcome:input.expectedOutcome||null,
    p_theme:input.theme||null,
    p_scope_level:input.scopeLevel||'nacional',
    p_region:input.region||null,
    p_department:input.department||null,
    p_municipality:input.municipality||null,
    p_evidence:input.evidence||[]
  });
  if(error) throw error;
  return data;
}

export async function createContribution(input){
  if(!supabase) throw new Error('Para aportar a una propuesta real debes ingresar a un piloto conectado.');
  const { data,error }=await supabase.rpc('submit_contribution',{
    p_proposal_id:input.proposalId,
    p_type:input.type,
    p_body:input.body,
    p_source_url:input.sourceUrl||null
  });
  if(error) throw error;
  return data;
}

export async function listBallots(){
  if(!supabase) return demo.ballots;
  const { data,error }=await supabase.from('public_ballot_integrity').select('*').order('ballot_id');
  if(error) throw error;
  return data||[];
}

export async function getBallotOptions(ballotId){
  if(!supabase) return [];
  const { data,error }=await supabase.from('ballot_options').select('id,ballot_id,proposal_id,label,sort_order,estimated_cost').eq('ballot_id',ballotId).order('sort_order');
  if(error) throw error;
  return data||[];
}

export async function requestEligibility(ballotId,rationale=''){
  if(!supabase) throw new Error('El piloto no está conectado.');
  const { data,error }=await supabase.rpc('request_ballot_eligibility',{p_ballot_id:ballotId,p_rationale:rationale||null});
  if(error) throw error;
  return data;
}

export async function castVote(ballotId,selection){
  if(!supabase) throw new Error('El piloto no está conectado.');
  const { data,error }=await supabase.rpc('cast_ballot',{p_ballot_id:ballotId,p_selection:selection});
  if(error) throw error;
  return data;
}
