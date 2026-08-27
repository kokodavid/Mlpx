// =============================================================================
// Email HTML templates — styled to match Milpress transactional email design
// =============================================================================

const LOGO_URL =
  'https://bdlfghvrbjjzybuexdwe.supabase.co/storage/v1/object/public/thumbnails/milpresslogo.png';

const APP_URL = 'https://milpress.org/';

// Shared wrappers
function emailWrapper(content: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0; padding:0; background-color:#f4f6f8; font-family: Arial, Helvetica, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f8; padding:40px 0;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px; background-color:#ffffff; border-radius:8px; overflow:hidden;">

          <!-- Logo -->
          <tr>
            <td align="center" style="padding:32px 24px 16px;">
              <img src="${LOGO_URL}" alt="Milpress" width="120"
                style="display:block; border:0; outline:none; text-decoration:none;" />
            </td>
          </tr>

          ${content}

          <!-- Footer -->
          <tr>
            <td style="padding:24px 32px; background-color:#f9fafb; font-size:12px; color:#9ca3af; text-align:center;">
              <p style="margin:0;">© 2026 Milpress. All rights reserved.</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function ctaButton(label: string, url: string): string {
  return `<a href="${url}"
    style="display:inline-block; background-color:#E85D04; color:#ffffff; text-decoration:none;
           font-size:15px; font-weight:600; padding:14px 28px; border-radius:6px;">
    ${label}
  </a>`;
}

function warningBox(text: string): string {
  return `<tr>
    <td style="padding:0 32px 24px;">
      <table width="100%" cellpadding="0" cellspacing="0"
        style="background-color:#fff7ed; border:1px solid #fed7aa; border-radius:8px;">
        <tr>
          <td style="padding:14px 18px; font-size:13px; color:#92400e; line-height:1.6;">
            ${text}
          </td>
        </tr>
      </table>
    </td>
  </tr>`;
}

// -----------------------------------------------------------------------------
// Org invite email
// -----------------------------------------------------------------------------
export function orgInviteTemplate(opts: {
  orgName: string;
  inviteEmail: string;
  role: string;
  appStoreUrl?: string;
  playStoreUrl?: string;
}): { subject: string; html: string } {
  const subject = `You've been invited to ${opts.orgName} on Milpress`;

  const appLink = opts.appStoreUrl || opts.playStoreUrl || APP_URL;

  const content = `
    <!-- Title -->
    <tr>
      <td style="padding:0 32px;">
        <h2 style="margin:0; font-size:22px; color:#111827; text-align:center;">
          You've been invited!
        </h2>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:16px 32px 24px; color:#374151; font-size:15px; line-height:1.6;">
        <p style="margin:0 0 12px;">
          <strong>${opts.orgName}</strong> has granted you premium access to Milpress
          as a <strong>${opts.role}</strong>.
        </p>
        <p style="margin:0;">
          To get started, download the app and sign in with this email address.
        </p>
      </td>
    </tr>

    ${warningBox(`<strong>Important:</strong> You must sign up or log in with
      <strong>${opts.inviteEmail}</strong> — your access is linked to this exact email address.`)}

    <!-- Steps -->
    <tr>
      <td style="padding:0 32px 24px; color:#374151; font-size:14px; line-height:2;">
        <ol style="margin:0; padding-left:20px;">
          <li>Download the Milpress app</li>
          <li>Sign up or log in with <strong>${opts.inviteEmail}</strong></li>
          <li>Your premium access activates automatically</li>
        </ol>
      </td>
    </tr>

    <!-- CTA -->
    <tr>
      <td align="center" style="padding:0 32px 32px;">
        ${ctaButton('Get the App', appLink)}
      </td>
    </tr>

    <!-- Disclaimer -->
    <tr>
      <td style="padding:0 32px 24px; font-size:12px; color:#9ca3af; text-align:center;">
        This invitation was sent to ${opts.inviteEmail}.<br>
        If you weren't expecting this, you can safely ignore this email.
      </td>
    </tr>`;

  return { subject, html: emailWrapper(content) };
}

// -----------------------------------------------------------------------------
// Sponsored grant invite email
// -----------------------------------------------------------------------------
export function sponsoredGrantTemplate(opts: {
  orgName: string;
  inviteEmail: string;
  validUntil?: string | null;
  appStoreUrl?: string;
  playStoreUrl?: string;
}): { subject: string; html: string } {
  const subject = `${opts.orgName} is sponsoring your Milpress access`;

  const appLink = opts.appStoreUrl || opts.playStoreUrl || APP_URL;

  const expiryRow = opts.validUntil
    ? `<tr>
        <td style="padding:0 32px 16px; font-size:13px; color:#6b7280; text-align:center;">
          Your sponsored access is valid until
          <strong>${new Date(opts.validUntil).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</strong>.
        </td>
      </tr>`
    : '';

  const content = `
    <!-- Title -->
    <tr>
      <td style="padding:0 32px;">
        <h2 style="margin:0; font-size:22px; color:#111827; text-align:center;">
          Premium access, on us!
        </h2>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:16px 32px 24px; color:#374151; font-size:15px; line-height:1.6;">
        <p style="margin:0 0 12px;">
          <strong>${opts.orgName}</strong> is sponsoring your full premium access to Milpress.
        </p>
        <p style="margin:0;">
          Download the app and sign in with your email to activate — no payment needed.
        </p>
      </td>
    </tr>

    ${expiryRow}

    ${warningBox(`<strong>Important:</strong> Sign up or log in with
      <strong>${opts.inviteEmail}</strong> to activate your sponsored access.`)}

    <!-- Steps -->
    <tr>
      <td style="padding:0 32px 24px; color:#374151; font-size:14px; line-height:2;">
        <ol style="margin:0; padding-left:20px;">
          <li>Download the Milpress app</li>
          <li>Sign up or log in with <strong>${opts.inviteEmail}</strong></li>
          <li>Premium access activates automatically — no payment needed</li>
        </ol>
      </td>
    </tr>

    <!-- CTA -->
    <tr>
      <td align="center" style="padding:0 32px 32px;">
        ${ctaButton('Get the App', appLink)}
      </td>
    </tr>

    <!-- Disclaimer -->
    <tr>
      <td style="padding:0 32px 24px; font-size:12px; color:#9ca3af; text-align:center;">
        This email was sent to ${opts.inviteEmail} on behalf of ${opts.orgName}.<br>
        If you weren't expecting this, you can safely ignore it.
      </td>
    </tr>`;

  return { subject, html: emailWrapper(content) };
}

// -----------------------------------------------------------------------------
// Org member removed email
// -----------------------------------------------------------------------------
export function memberRemovedTemplate(opts: {
  orgName: string;
  inviteEmail: string;
}): { subject: string; html: string } {
  const subject = `Your membership in ${opts.orgName} has ended`;

  const content = `
    <!-- Title -->
    <tr>
      <td style="padding:0 32px;">
        <h2 style="margin:0; font-size:22px; color:#111827; text-align:center;">
          Your membership has ended
        </h2>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:16px 32px 24px; color:#374151; font-size:15px; line-height:1.6;">
        <p style="margin:0;">
          Your membership in <strong>${opts.orgName}</strong> and the associated
          premium access to Milpress has been removed.
        </p>
      </td>
    </tr>

    <!-- Upgrade box -->
    <tr>
      <td style="padding:0 32px 24px;">
        <table width="100%" cellpadding="0" cellspacing="0"
          style="background-color:#f9fafb; border:1px solid #e5e7eb; border-radius:8px; text-align:center;">
          <tr>
            <td style="padding:24px;">
              <p style="margin:0 0 6px; font-size:14px; color:#111827; font-weight:600;">
                Want to keep your premium access?
              </p>
              <p style="margin:0 0 16px; font-size:13px; color:#6b7280;">
                Subscribe directly to continue learning without interruption.
              </p>
              ${ctaButton('View Plans', 'https://milpress.org/')}
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Reassurance -->
    <tr>
      <td style="padding:0 32px 24px; font-size:13px; color:#6b7280; text-align:center; line-height:1.6;">
        Your progress and completed lessons are always saved — you won't lose anything.
      </td>
    </tr>`;

  return { subject, html: emailWrapper(content) };
}

// -----------------------------------------------------------------------------
// Org admin invite email (org portal access with temp password)
// -----------------------------------------------------------------------------
export function orgAdminInviteTemplate(opts: {
  orgName: string;
  inviteEmail: string;
  tempPassword: string;
  orgPortalUrl: string;
}): { subject: string; html: string } {
  const subject = `You've been added as an admin for ${opts.orgName} on Milpress`;

  const content = `
    <!-- Title -->
    <tr>
      <td style="padding:0 32px;">
        <h2 style="margin:0; font-size:22px; color:#111827; text-align:center;">
          Your admin access is ready
        </h2>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:16px 32px 24px; color:#374151; font-size:15px; line-height:1.6;">
        <p style="margin:0 0 12px;">
          You've been added as an <strong>Admin</strong> for
          <strong>${opts.orgName}</strong> on the Milpress Organization Portal.
        </p>
        <p style="margin:0;">
          Use the credentials below to sign in. You can update your password anytime after logging in.
        </p>
      </td>
    </tr>

    <!-- Credentials box -->
    <tr>
      <td style="padding:0 32px 24px;">
        <table width="100%" cellpadding="0" cellspacing="0"
          style="background-color:#f0f9ff; border:1px solid #bae6fd; border-radius:8px;">
          <tr>
            <td style="padding:20px 24px;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="font-size:13px; color:#0369a1; font-weight:600; padding-bottom:6px;">
                    Email
                  </td>
                </tr>
                <tr>
                  <td style="font-size:15px; color:#111827; font-family:monospace; padding-bottom:16px;">
                    ${opts.inviteEmail}
                  </td>
                </tr>
                <tr>
                  <td style="font-size:13px; color:#0369a1; font-weight:600; padding-bottom:6px;">
                    Temporary Password
                  </td>
                </tr>
                <tr>
                  <td style="font-size:15px; color:#111827; font-family:monospace; letter-spacing:1px;">
                    ${opts.tempPassword}
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- CTA -->
    <tr>
      <td align="center" style="padding:0 32px 24px;">
        ${ctaButton('Sign in to the Org Portal', opts.orgPortalUrl)}
      </td>
    </tr>

    ${warningBox(`For security, please change your password after your first login.
      Your account is linked to <strong>${opts.inviteEmail}</strong> — use this exact email to sign in.`)}

    <!-- Disclaimer -->
    <tr>
      <td style="padding:16px 32px 24px; font-size:12px; color:#9ca3af; text-align:center;">
        This invitation was sent to ${opts.inviteEmail} on behalf of ${opts.orgName}.<br>
        If you weren't expecting this, please contact Milpress support.
      </td>
    </tr>`;

  return { subject, html: emailWrapper(content) };
}

// -----------------------------------------------------------------------------
// Grant revoked email
// -----------------------------------------------------------------------------
export function grantRevokedTemplate(opts: {
  orgName: string;
  inviteEmail: string;
  reason?: string | null;
}): { subject: string; html: string } {
  const subject = `Your sponsored Milpress access has ended`;

  const reasonRow = opts.reason
    ? `<tr>
        <td style="padding:0 32px 16px; font-size:13px; color:#6b7280; text-align:center;">
          Reason: ${opts.reason}
        </td>
      </tr>`
    : '';

  const content = `
    <!-- Title -->
    <tr>
      <td style="padding:0 32px;">
        <h2 style="margin:0; font-size:22px; color:#111827; text-align:center;">
          Your sponsored access has ended
        </h2>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:16px 32px 24px; color:#374151; font-size:15px; line-height:1.6;">
        <p style="margin:0;">
          Your premium access sponsored by <strong>${opts.orgName}</strong> has been revoked.
        </p>
      </td>
    </tr>

    ${reasonRow}

    <!-- Upgrade box -->
    <tr>
      <td style="padding:0 32px 24px;">
        <table width="100%" cellpadding="0" cellspacing="0"
          style="background-color:#f9fafb; border:1px solid #e5e7eb; border-radius:8px; text-align:center;">
          <tr>
            <td style="padding:24px;">
              <p style="margin:0 0 6px; font-size:14px; color:#111827; font-weight:600;">
                Want to keep your premium access?
              </p>
              <p style="margin:0 0 16px; font-size:13px; color:#6b7280;">
                Subscribe directly to continue learning without interruption.
              </p>
              ${ctaButton('View Plans', APP_URL)}
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Reassurance -->
    <tr>
      <td style="padding:0 32px 24px; font-size:13px; color:#6b7280; text-align:center; line-height:1.6;">
        Your progress and completed lessons are always saved — you won't lose anything.
      </td>
    </tr>`;

  return { subject, html: emailWrapper(content) };
}
