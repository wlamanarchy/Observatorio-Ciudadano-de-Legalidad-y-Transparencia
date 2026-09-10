import { createClient } from "@supabase/supabase-js";

const defaultUrl = "https://hiuqhcglnjfalizoybik.supabase.co";
const defaultPublishableKey = "sb_publishable_l61VZqrY9734jr_VYCiimw_p7szutXE";

const url = import.meta.env.VITE_SUPABASE_URL || defaultUrl;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || defaultPublishableKey;

export const supabaseEnabled = Boolean(url && key);
export const supabase = supabaseEnabled
  ? createClient(url, key, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    })
  : null;
