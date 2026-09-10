-- pgcrypto se instala en el schema `extensions` de Supabase.
-- Las funciones críticas conservan search_path fijo e incluyen explícitamente dicho schema.

alter function public.hash_jsonb(jsonb)
  set search_path=public,extensions,pg_temp;

alter function public.append_integrity_event(text,text,uuid,text,jsonb)
  set search_path=public,extensions,pg_temp;

alter function public.cast_ballot(uuid,jsonb)
  set search_path=public,extensions,pg_temp;
