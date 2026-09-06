// ============================================================
// 📧 EDGE FUNCTION "notifier" — envoie des emails via Brevo.
// 2 types : "bienvenue" (inscription) et "avis" (nouvel avis).
// Vérifie la réponse réelle de Brevo (sinon on ne sait pas si le mail part).
// ============================================================
import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY') ?? '';
const SENDER_EMAIL = Deno.env.get('SENDER_EMAIL') ?? 'ngongangdjomo@gmail.com';
const DASH_URL = 'https://damocles2002.github.io/Avis-Google/dashboard.html';

// Envoie un email via Brevo et retourne { ok, message }
async function envoyerBrevo(to, subject, html) {
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'api-key': BREVO_API_KEY },
    body: JSON.stringify({
      sender: { name: 'DAMAVIS', email: SENDER_EMAIL },
      to: [{ email: to }],
      subject,
      htmlContent: html,
    }),
  });
  const text = await res.text();
  if (!res.ok) {
    return { ok: false, message: `Brevo ${res.status}: ${text}` };
  }
  return { ok: true, message: 'envoyé' };
}

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const record = body.record;
    const type = body.type || 'avis';

    // ── CAS BIENVENUE ───────────────────────────────────────
    if (type === 'bienvenue' || (record?.nom && record?.email_patron && !record?.id_restaurant)) {
      const nom = record.nom;
      const email = record.email_patron;
      if (!email) return new Response('OK', { status: 200 });
      const r = await envoyerBrevo(email, `🎉 Bienvenue sur DAMAVIS — ${nom}`, `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #eee;border-radius:12px">
          <h2 style="color:#1a73e8;margin:0 0 8px">🎉 Bienvenue sur DAMAVIS !</h2>
          <p style="color:#555">Votre établissement <strong>${nom}</strong> est maintenant prêt.</p>
          <p style="color:#555">Avec DAMAVIS, vous pouvez :</p>
          <ul style="color:#555">
            <li>📱 Générer votre QR code pour les tables</li>
            <li>⭐ Recevoir les avis de vos clients</li>
            <li>🛡️ Protéger votre note Google</li>
          </ul>
          <p style="color:#555">Votre <strong>essai gratuit de 14 jours</strong> commence maintenant.</p>
          <a href="${DASH_URL}" style="display:inline-block;background:#1a73e8;color:white;padding:12px 24px;border-radius:8px;text-decoration:none">Accéder à mon tableau de bord →</a>
        </div>
      `);
      return new Response(JSON.stringify(r), { status: 200 });
    }

    // ── CAS AVIS ────────────────────────────────────────────
    const idResto = record?.id_restaurant;
    if (!idResto) return new Response('OK', { status: 200 });

    const { data: resto } = await supabase
      .from('restaurants')
      .select('nom, email_patron')
      .eq('id', idResto)
      .single();

    if (!resto?.email_patron) return new Response('OK', { status: 200 });

    const note = record.note ? `${record.note}/5` : '—';
    const r = await envoyerBrevo(resto.email_patron, `📢 Nouvel avis reçu — ${resto.nom}`, `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #eee;border-radius:12px">
        <h2 style="color:#1a73e8;margin:0 0 8px">📢 Nouvel avis reçu</h2>
        <p style="color:#555">Un client vient de laisser un avis pour <strong>${resto.nom}</strong>.</p>
        <div style="background:#f7f7fb;padding:16px;border-radius:8px;margin:16px 0">
          <p style="margin:0 0 6px"><strong>Note :</strong> ${note}</p>
          <p style="margin:0;color:#555">${record.commentaire || 'Aucun commentaire'}</p>
        </div>
        <a href="${DASH_URL}" style="display:inline-block;background:#1a73e8;color:white;padding:12px 24px;border-radius:8px;text-decoration:none">Voir mes avis →</a>
      </div>
    `);
    return new Response(JSON.stringify(r), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 200 });
  }
});
