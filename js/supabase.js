// ============================================
// CLIENT SUPABASE — initialisé une seule fois
// Alias _supabase et sb pour compatibilité avec toutes les pages.
// ============================================
const _supabase = window.supabase.createClient(CONFIG.SB_URL, CONFIG.SB_KEY);
const sb = _supabase; // alias (utilisé par dashboard.html)
