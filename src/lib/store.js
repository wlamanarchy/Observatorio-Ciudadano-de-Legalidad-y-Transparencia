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
    entidadTipo: item.entidadTipo || "",
    ...item,
  };
}

function localRead(key) {
  const value = window.localStorage?.getItem(key);
  if (!value) throw new Error("sin datos");
  return value;
}

export function backendMode() {
  return supabaseEnabled ? "supabase" : "local";
}

export async function getAuthContext() {
  if (!supabaseEnabled) {
    return {
      user: { id: "local-demo", email: "demo@local" },
      profile: { global_role: "admin_nacional", display_name: "Modo local" },
      roles: [{ role: "admin_nacional", region: null, department: null }],
      canCurate: true,
    };
  }

  const { data: { session } } = await supabase.auth.getSession();
  if (!session?.user) return { user: null, profile: null, roles: [], canCurate: false };

  const [profileRes, rolesRes] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", session.user.id).maybeSingle(),
    supabase.from("territorial_roles").select("*").eq("user_id", session.user.id).eq("active", true),
  ]);

  const profile = profileRes.data || null;
  const roles = rolesRes.data || [];
  const canCurate = ["admin_nacional", "curador_nacional"].includes(profile?.global_role) || roles.length > 0;
  return { user: session.user, profile, roles, canCurate };
}

export function onAuthChange(callback) {
  if (!supabaseEnabled) return () => {};
  const { data } = supabase.auth.onAuthStateChange(() => callback());
  return () => data.subscription.unsubscribe();
}

export async function signInWithEmail(email) {
  if (!supabaseEnabled) return { error: new Error("Supabase no está configurado") };
  return supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: window.location.href.split("#")[0] },
  });
}

export async function signOut() {
  if (!supabaseEnabled) return;
  await supabase.auth.signOut();
}

function rowToFinding(row) {
  const payload = normalizar(row.payload || {});
  return {
    ...payload,
    id: row.id,
    folio: row.folio ?? payload.folio,
    nivel: row.level || payload.nivel,
    region: row.region || payload.region,
    departamento: row.department || payload.departamento,
    municipio: row.municipality || payload.municipio,
    territorio: row.territory || payload.territorio,
    entidad: row.entity_name || payload.entidad,
    actoTipo: row.act_type || payload.actoTipo,
    actoId: row.act_id || payload.actoId,
    fecha: row.act_date || payload.fecha,
    clase: row.finding_class || payload.clase,
    verificacion: row.verification_status || payload.verificacion,
    replica: row.replica_status || payload.replica,
  };
}

function rowToReport(row) {
  return normalizar({
    ...(row.payload || {}),
    id: row.id,
    recibido: row.received_at?.slice?.(0, 10) || row.payload?.recibido,
    nivel: row.level || row.payload?.nivel,
    region: row.region || row.payload?.region,
    departamento: row.department || row.payload?.departamento,
    municipio: row.municipality || row.payload?.municipio,
    territorio: row.territory || row.payload?.territorio,
    entidad: row.entity_name || row.payload?.entidad,
    actoTipo: row.act_type || row.payload?.actoTipo,
    actoId: row.act_id || row.payload?.actoId,
    fecha: row.act_date || row.payload?.fecha,
    clase: row.class_hint || row.payload?.clase,
    estadoInterno: row.status,
    contacto: row.reporter_private?.[0]?.contact || row.reporter_private?.contact || "",
  });
}

export async function loadState() {
  if (!supabaseEnabled) {
    let parsed;
    try {
      parsed = JSON.parse(localRead(STORAGE_KEY));
    } catch {
      try {
        parsed = JSON.parse(localRead(LEGACY_STORAGE_KEY));
      } catch {
        parsed = { fichas: [], reportes: [] };
      }
    }
    return {
      fichas: (parsed.fichas || []).map(normalizar),
      reportes: (parsed.reportes || []).map(normalizar),
    };
  }

  const [{ data: findings, error: findingsError }, auth] = await Promise.all([
    supabase.from("findings").select("*").order("folio", { ascending: false }),
    getAuthContext(),
  ]);
  if (findingsError) throw findingsError;

  let reportes = [];
  if (auth.canCurate) {
    const { data, error } = await supabase
      .from("reports")
      .select("*, reporter_private(contact)")
      .in("status", ["received", "triage", "verification"])
      .order("received_at", { ascending: false });
    if (error) throw error;
    reportes = (data || []).map(rowToReport);
  }

  return {
    fichas: (findings || []).map(rowToFinding),
    reportes,
  };
}

export async function saveLocalState(state) {
  window.localStorage?.setItem(STORAGE_KEY, JSON.stringify(state));
}

export async function upsertFinding(f) {
  if (!supabaseEnabled) return;
  const row = {
    id: f.id,
    level: f.nivel || "nacional",
    region: f.region || null,
    department: f.departamento || null,
    municipality: f.municipio || null,
    territory: f.territorio || null,
    entity_name: f.entidad || "",
    act_type: f.actoTipo || "",
    act_id: f.actoId || "",
    act_date: f.fecha || null,
    finding_class: f.clase || "integridad",
    verification_status: f.verificacion || "sinverificar",
    replica_status: f.replica || "no_notificado",
    published: Boolean(f.publicado || (f.verificacion === "documentado" && f.replica !== "no_notificado")),
    payload: f,
  };
  const { error } = await supabase.from("findings").upsert(row, { onConflict: "id" });
  if (error) throw error;
}

export async function submitReport(report) {
  if (!supabaseEnabled) return null;
  const { contacto = "", ...publicReport } = report;
  const { data, error } = await supabase.rpc("submit_report", {
    p_report: publicReport,
    p_contact: contacto || null,
  });
  if (error) throw error;
  return data;
}

export async function resolveReport(report, finding) {
  if (!supabaseEnabled) return;
  const { error } = await supabase.rpc("resolve_report", {
    p_report_id: report.id,
    p_finding: finding || null,
    p_outcome: finding ? "promoted" : "discarded",
  });
  if (error) throw error;
}
