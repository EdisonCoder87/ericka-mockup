/* ============================================================================
   Ericka Portal — Supabase connection config
   ----------------------------------------------------------------------------
   PASTE YOUR TWO VALUES BELOW (from Supabase → Project Settings → API):
     1. Project URL      → SUPABASE_URL
     2. anon public key  → SUPABASE_ANON_KEY
   Both are safe to ship in a public webpage — the anon key is designed for this.
   ============================================================================ */

const SUPABASE_URL      = "https://bewfcqcmleuznaaptqiq.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJld2ZjcWNtbGV1em5hYXB0cWlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczOTA5OTEsImV4cCI6MjEwMjk2Njk5MX0.b7nkzxmrm_FO-f8avYk7D1_t2YoEl0UfPqXR25RWavo";

// --- do not edit below ------------------------------------------------------
const _configured = !SUPABASE_URL.startsWith("PASTE_") && !SUPABASE_ANON_KEY.startsWith("PASTE_");
window.ERICKA_CONFIGURED = _configured;
window.sb = _configured
  ? supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;
