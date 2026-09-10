import { supabase, supabaseEnabled } from './supabase.js';

const demo={
  processes:[{id:'demo-process',title:'Visión Colombia 2050 — piloto',process_type:'vision_largo_plazo',legal_nature:'consultivo',scope_level:'nacional',status:'deliberation'}],
  proposals:[],diagnostics:[],ballots:[],results:[],entityTypes:[],scopeTypes:[],registries:[],scopes:[]
};

export const backendMode=()=>supabaseEnabled?'supabase':'demo';
const must=()=>{if(!supabase)throw new Error('El backend del piloto aún no está configurado.');return supabase;};
const unwrap=({data,error})=>{if(error)throw error;return data;};

export async function getMyRoles(){
  if(!supabase)return [];
  return unwrap(await supabase.rpc('my_governance_roles'))||[];
}

export async function getSession(){
  if(!supabase)return {user:null,profile:null,roles:[]};
  const {data:{session},error}=await supabase.auth.getSession();
  if(error)throw error;
  if(!session?.user)return {user:null,profile:null,roles:[]};
  const [{data:profile},{data:roles,error:roleError}]=await Promise.all([
    supabase.from('citizen_profiles').select('*').eq('id',session.user.id).maybeSingle(),
    supabase.rpc('my_governance_roles')
  ]);
  if(roleError)throw roleError;
  return {user:session.user,profile:profile||null,roles:roles||[]};
}

export function onAuthChange(callback){
  if(!supabase)return()=>{};
  const {data}=supabase.auth.onAuthStateChange(async(_event,session)=>{
    let profile=null,roles=[];
    if(session?.user){
      const [p,r]=await Promise.all([
        supabase.from('citizen_profiles').select('*').eq('id',session.user.id).maybeSingle(),
        supabase.rpc('my_governance_roles')
      ]);
      profile=p.data||null;roles=r.data||[];
    }
    callback({user:session?.user||null,profile,roles});
  });
  return()=>data.subscription.unsubscribe();
}

export async function signInWithEmail(email){
  const client=must();
  return client.auth.signInWithOtp({email,options:{emailRedirectTo:window.location.href.split('#')[0].split('?')[0]}});
}
export async function signOut(){const client=must();const {error}=await client.auth.signOut();if(error)throw error;}

export async function listProcesses(){
  if(!supabase)return demo.processes;
  return unwrap(await supabase.from('public_process_directory').select('*').order('created_at',{ascending:false}))||[];
}
export async function listDiagnostics(){
  if(!supabase)return demo.diagnostics;
  return unwrap(await supabase.from('diagnostics').select('id,process_id,title,description,baseline,source_url,observatory_reference,created_at').order('created_at',{ascending:false}))||[];
}
export async function listProposals(){
  if(!supabase)return demo.proposals;
  return unwrap(await supabase.from('public_proposal_feed').select('*').order('created_at',{ascending:false}))||[];
}
export async function listEntityCatalog(){
  if(!supabase)return demo.entityTypes;
  return unwrap(await supabase.from('public_entity_type_catalog').select('*').order('sort_order',{ascending:true}))||[];
}
export async function listScopeTypeCatalog(){
  if(!supabase)return demo.scopeTypes;
  return unwrap(await supabase.from('public_scope_type_catalog').select('*').order('sort_order',{ascending:true}))||[];
}
export async function listReferenceRegistries(){
  if(!supabase)return demo.registries;
  return unwrap(await supabase.from('public_reference_registries').select('*').order('name',{ascending:true}))||[];
}
export async function listParticipationScopes(){
  if(!supabase)return demo.scopes;
  return unwrap(await supabase.from('public_participation_scopes').select('*').order('name',{ascending:true}))||[];
}
export async function listContributions(proposalId){
  if(!supabase)return [];
  return unwrap(await supabase.from('contributions').select('id,proposal_id,contribution_type,body,source_url,status,created_at').eq('proposal_id',proposalId).eq('status','visible').order('created_at',{ascending:true}))||[];
}
export async function listBallots(){
  if(!supabase)return demo.ballots;
  return unwrap(await supabase.from('public_ballot_integrity').select('*').order('ballot_id'))||[];
}
export async function listBallotResults(){
  if(!supabase)return demo.results;
  return unwrap(await supabase.rpc('list_public_ballot_results'))||[];
}
export async function getBallotOptions(ballotId){
  if(!supabase)return [];
  return unwrap(await supabase.from('ballot_options').select('id,ballot_id,proposal_id,label,sort_order,estimated_cost').eq('ballot_id',ballotId).order('sort_order'))||[];
}

export async function createProposal(input){
  const client=must();
  return unwrap(await client.rpc('submit_citizen_proposal',{
    p_process_id:input.processId,p_title:input.title,p_summary:input.summary,p_problem:input.problem,
    p_expected_outcome:input.expectedOutcome||null,p_theme:input.theme||null,p_scope_level:input.scopeLevel||'nacional',
    p_region:input.region||null,p_department:input.department||null,p_municipality:input.municipality||null,p_evidence:input.evidence||[]
  }));
}
export async function createContribution(input){
  const client=must();
  return unwrap(await client.rpc('submit_contribution',{p_proposal_id:input.proposalId,p_type:input.type,p_body:input.body,p_source_url:input.sourceUrl||null}));
}
export async function requestEligibility(ballotId,rationale=''){
  const client=must();return unwrap(await client.rpc('request_ballot_eligibility',{p_ballot_id:ballotId,p_rationale:rationale||null}));
}
export async function castVote(ballotId,selection){
  const client=must();return unwrap(await client.rpc('cast_ballot',{p_ballot_id:ballotId,p_selection:selection}));
}

export async function bootstrapPlatformAdmin(code){
  const client=must();return unwrap(await client.rpc('bootstrap_platform_admin',{p_code:code}));
}
export async function adminUserDirectory(){const client=must();return unwrap(await client.rpc('admin_user_directory'))||[];}
export async function adminListGovernanceRoles(){const client=must();return unwrap(await client.rpc('admin_list_governance_roles'))||[];}
export async function adminAssignRole({userId,role,institutionId=null,processId=null,expiresAt=null}){
  const client=must();return unwrap(await client.rpc('admin_assign_governance_role',{p_user_id:userId,p_role:role,p_institution_id:institutionId,p_process_id:processId,p_expires_at:expiresAt}));
}
export async function adminRevokeRole(roleId){const client=must();return unwrap(await client.rpc('admin_revoke_governance_role',{p_role_id:roleId}));}
export async function adminSetVerification(userId,level){const client=must();return unwrap(await client.rpc('admin_set_verification_level',{p_user_id:userId,p_level:level}));}
export async function adminPendingEligibility(){const client=must();return unwrap(await client.rpc('admin_pending_eligibility_requests'))||[];}
export async function adminDecideEligibility(requestId,approve,reason=''){
  const client=must();return unwrap(await client.rpc('admin_decide_eligibility',{p_request_id:requestId,p_approve:approve,p_reason:reason||null}));
}
export async function adminListProcesses(){const client=must();return unwrap(await client.rpc('admin_list_processes'))||[];}
export async function adminListBallots(){const client=must();return unwrap(await client.rpc('admin_list_ballots'))||[];}
export async function adminCreateInstitution(input){
  const client=must();return unwrap(await client.rpc('admin_create_institution',{
    p_name:input.name,p_institution_type:input.institutionType,p_territorial_level:input.territorialLevel||null,
    p_region:input.region||null,p_department:input.department||null,p_municipality:input.municipality||null,p_official_url:input.officialUrl||null
  }));
}
export async function adminCreateProcess(input){
  const client=must();return unwrap(await client.rpc('admin_create_process',{
    p_title:input.title,p_process_type:input.processType,p_legal_nature:input.legalNature,p_scope_level:input.scopeLevel,
    p_rules:input.rules||{},p_institution_id:input.institutionId||null,p_region:input.region||null,p_department:input.department||null,p_municipality:input.municipality||null
  }));
}
export async function adminSetProcessStatus(processId,status){const client=must();return unwrap(await client.rpc('admin_set_process_status',{p_process_id:processId,p_status:status}));}
export async function adminPublishConsensusRules(input){
  const client=must();return unwrap(await client.rpc('admin_publish_consensus_rules',{
    p_process_id:input.processId,p_min_participants:input.minParticipants||null,p_min_turnout_pct:input.minTurnoutPct||null,
    p_min_support_pct:input.minSupportPct||null,p_min_territories:input.minTerritories||null,p_min_territory_support_pct:input.minTerritorySupportPct||null,p_additional_rules:input.additionalRules||{}
  }));
}
export async function adminCreateBallot(input){
  const client=must();return unwrap(await client.rpc('admin_create_ballot',{
    p_process_id:input.processId,p_title:input.title,p_method:input.method,p_rules:input.rules||{},p_verification_required:input.verificationRequired||1,p_integrity_level:input.integrityLevel||'pilot'
  }));
}
export async function adminAddBallotOption(input){
  const client=must();return unwrap(await client.rpc('admin_add_ballot_option',{p_ballot_id:input.ballotId,p_label:input.label,p_proposal_id:input.proposalId||null,p_estimated_cost:input.estimatedCost||null}));
}
export async function adminOpenBallot(input){
  const client=must();return unwrap(await client.rpc('admin_open_ballot',{p_ballot_id:input.ballotId,p_opens_at:input.opensAt,p_closes_at:input.closesAt,p_software_commit:input.softwareCommit||null}));
}
export async function adminCloseAndTally(ballotId,notes=''){const client=must();return unwrap(await client.rpc('admin_close_and_tally_ballot',{p_ballot_id:ballotId,p_notes:notes||null}));}
export async function adminCertifyBallot(ballotId,notes=''){const client=must();return unwrap(await client.rpc('admin_certify_ballot',{p_ballot_id:ballotId,p_notes:notes||null}));}
