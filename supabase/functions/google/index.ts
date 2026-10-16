// Edge Function DAMAVIS — Google Business Profile
// Gère : échange du code OAuth, stockage du token, lecture des avis Google.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CLIENT_ID = Deno.env.get('GOOGLE_CLIENT_ID') ?? ''
const CLIENT_SECRET = Deno.env.get('GOOGLE_CLIENT_SECRET') ?? ''
// URI de redirection : page statique hébergée sur GitHub Pages
const REDIRECT_URI = 'https://damocles2002.github.io/Avis-Google/oauth-callback.html'

const cors = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const body = await req.json().catch(() => ({}))
  const { action } = body

  // ── 1) auth : échanger le code OAuth → stocker le refresh_token ──
  if (action === 'auth') {
    const { code, idResto } = body
    if (!code || !idResto) {
      return new Response(JSON.stringify({ ok: false, error: 'code ou idResto manquant' }), { headers: cors })
    }
    const tr = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        redirect_uri: REDIRECT_URI,
        grant_type: 'authorization_code',
      }),
    })
    const tokens = await tr.json()
    if (!tokens.refresh_token) {
      return new Response(JSON.stringify({ ok: false, error: 'Aucun refresh_token reçu (l\'accès API n\'est peut-être pas encore approuvé par Google)', tokens }), { headers: cors })
    }
    const { data: r } = await supabase.from('restaurants').select('settings').eq('id', idResto).single()
    const settings = { ...(r?.settings || {}), google: { refresh_token: tokens.refresh_token, connecte: true } }
    await supabase.from('restaurants').update({ settings }).eq('id', idResto)
    return new Response(JSON.stringify({ ok: true }), { headers: cors })
  }

  // ── 2) statut : le resto est-il connecté à Google ? ──
  if (action === 'statut') {
    const { idResto } = body
    const { data: r } = await supabase.from('restaurants').select('settings').eq('id', idResto).single()
    const connecte = !!(r?.settings?.google?.refresh_token)
    return new Response(JSON.stringify({ ok: true, connecte }), { headers: cors })
  }

  // ── 3) deconnexion : supprimer le token Google ──
  if (action === 'deconnexion') {
    const { idResto } = body
    const { data: r } = await supabase.from('restaurants').select('settings').eq('id', idResto).single()
    const settings = { ...(r?.settings || {}) }
    delete settings.google
    await supabase.from('restaurants').update({ settings }).eq('id', idResto)
    return new Response(JSON.stringify({ ok: true }), { headers: cors })
  }

  // ── 4) avis : lire les avis Google du resto ──
  if (action === 'avis') {
    const { idResto } = body
    const { data: r } = await supabase.from('restaurants').select('settings').eq('id', idResto).single()
    const refresh_token = r?.settings?.google?.refresh_token
    if (!refresh_token) {
      return new Response(JSON.stringify({ ok: false, error: 'Non connecté à Google' }), { headers: cors })
    }

    // Rafraîchir l'access token
    const tr = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        refresh_token,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        grant_type: 'refresh_token',
      }),
    })
    const tokens = await tr.json()
    const access_token = tokens.access_token
    if (!access_token) {
      return new Response(JSON.stringify({ ok: false, error: 'Échec rafraîchissement token', tokens }), { headers: cors })
    }

    // 1. Lister les comptes
    const accRes = await fetch('https://mybusiness.googleapis.com/v4/accounts', {
      headers: { Authorization: `Bearer ${access_token}` },
    })
    const accData = await accRes.json()
    const accounts = accData.accounts || []

    // 2. Pour chaque compte → locations → reviews
    const avis: any[] = []
    for (const acc of accounts) {
      const locRes = await fetch(
        `https://mybusiness.googleapis.com/v4/accounts/${acc.name}/locations?pageSize=100`,
        { headers: { Authorization: `Bearer ${access_token}` } },
      )
      const locData = await locRes.json()
      for (const loc of (locData.locations || [])) {
        const revRes = await fetch(
          `https://mybusiness.googleapis.com/v4/accounts/${acc.name}/locations/${loc.name}/reviews?pageSize=50`,
          { headers: { Authorization: `Bearer ${access_token}` } },
        )
        const revData = await revRes.json()
        for (const rev of (revData.reviews || [])) {
          avis.push({
            nom: rev.reviewer?.displayName || 'Client Google',
            note: rev.starRating,
            commentaire: rev.comment || '',
            date: rev.createTime,
            reponse_resto: rev.reviewReply?.comment || '',
            source: 'google',
          })
        }
      }
    }

    return new Response(JSON.stringify({ ok: true, avis }), { headers: cors })
  }

  return new Response(JSON.stringify({ ok: false, error: 'action inconnue' }), { headers: cors })
})
