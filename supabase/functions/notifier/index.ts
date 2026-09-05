// ============================================================
// 📧 EDGE FUNCTION "notifier" — envoie un email au restaurant
// quand un nouvel avis est déposé (via Brevo).
// ============================================================
import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY') ?? '';
const SENDER_EMAIL = Deno.env.get('SENDER_EMAIL') ?? 'ngongangdjomo@gmail.com';

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const record = body.record;
    const idResto = record?.id_restaurant;
    if (!idResto) return new Response('OK', { status: 200 });

    // Récupérer le nom + email du restaurant (service_role contourne RLS)
    const { data: resto } = await supabase
      .from('restaurants')
      .select('nom, email_patron')
      .eq('id', idResto)
      .single();

    if (!resto?.email_patron) return new Response('OK', { status: 200 });

    const note = record.note ? `${record.note}/5` : '—';

    // Envoyer l'email via Brevo
    await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': BREVO_API_KEY,
      },
      body: JSON.stringify({
        sender: { name: 'DAMAVIS', email: SENDER_EMAIL },
        to: [{ email: resto.email_patron, name: resto.nom }],
        subject: `📢 Nouvel avis reçu — ${resto.nom}`,
        htmlContent: `
          <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #eee;border-radius:12px">
            <h2 style="color:#6c63ff;margin:0 0 8px">📢 Nouvel avis reçu</h2>
            <p style="color:#555">Un client vient de laisser un avis pour <strong>${resto.nom}</strong>.</p>
            <div style="background:#f7f7fb;padding:16px;border-radius:8px;margin:16px 0">
              <p style="margin:0 0 6px"><strong>Note :</strong> ${note}</p>
              <p style="margin:0;color:#555">${record.commentaire || 'Aucun commentaire'}</p>
            </div>
            <a href="https://damocles2002.github.io/Avis-Google/dashboard.html" style="display:inline-block;background:#6c63ff;color:white;padding:12px 24px;border-radius:8px;text-decoration:none">Voir mes avis →</a>
          </div>
        `
      })
    });

    return new Response('OK', { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 200 });
  }
});
