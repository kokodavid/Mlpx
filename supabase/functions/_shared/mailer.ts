// =============================================================================
// Shared SMTP email helper — uses Hostinger SMTP via nodemailer
// =============================================================================

import nodemailer from 'npm:nodemailer@6.9.9';

export interface EmailPayload {
  to: string | string[];
  subject: string;
  html: string;
  from?: string;
  fromName?: string;
}

export async function sendEmail(payload: EmailPayload): Promise<void> {
  const host      = Deno.env.get('SMTP_HOST')      ?? 'smtp.hostinger.com';
  const port      = parseInt(Deno.env.get('SMTP_PORT') ?? '465', 10);
  const username  = Deno.env.get('SMTP_USERNAME')!;
  const password  = Deno.env.get('SMTP_PASSWORD')!;
  const fromEmail = payload.from     ?? Deno.env.get('SMTP_FROM_EMAIL') ?? username;
  const fromName  = payload.fromName ?? Deno.env.get('SMTP_FROM_NAME')  ?? 'Milpress Educational';

  if (!username || !password) {
    throw new Error('SMTP_USERNAME and SMTP_PASSWORD must be set');
  }

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: true, // port 465 uses implicit TLS
    auth: { user: username, pass: password },
  });

  const recipients = Array.isArray(payload.to) ? payload.to.join(', ') : payload.to;

  await transporter.sendMail({
    from:    `"${fromName}" <${fromEmail}>`,
    to:      recipients,
    subject: payload.subject,
    html:    payload.html,
  });
}
