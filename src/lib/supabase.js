import { createClient } from "@supabase/supabase-js";

// La clave publishable está diseñada para ejecutarse en el navegador.
// Nunca use aquí service_role ni secretos administrativos.
const fallbackUrl = "https://bicpezhzvxjnkiptiqsq.supabase.co";
const fallbackPublishableKey = "sb_publishable_zHTdTPH0nsSqb1qU62pcng_3o3BeQeG";

const url = import.meta.env.VITE_SUPABASE_URL || fallbackUrl;
const publishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY || fallbackPublishableKey;

export const supabaseEnabled = Boolean(url && publishableKey);

export const supabase = supabaseEnabled
  ? createClient(url, publishableKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    })
  : null;
