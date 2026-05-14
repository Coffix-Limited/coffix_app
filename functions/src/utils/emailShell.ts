export function wrapInEmailShell(content: string): string {
  const logoUrl = process.env.LOGO_URL ?? "";

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  </head>
  
  <body style="margin:0;padding:32px 0;background-color:#f5f5f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;">
    <table width="900" align="center" cellpadding="0" cellspacing="0" border="0" style="background-color:#ffffff;border:none;border-collapse:collapse;">
      <tr>
        <td align="center" style="padding:32px 0 16px;">
          <img src="${logoUrl}" alt="Coffix" height="48" style="display:block;" />
        </td>
      </tr>
      <tr>

        <td style="padding:24px 48px 48px;color:#1a1a1a;font-size:14px;line-height:1.6;">
          ${content}
        </td>
      </tr>
      <tr>
        <td style="padding:24px 48px 32px;border-top:1px solid #e0e0e0;color:#666666;font-size:12px;line-height:1.8;text-align:center;">
          <p style="margin:0 0 4px;">This is an automatically-generated message from the Coffix app.</p>
          <p style="margin:0 0 4px;">If you did not make this request, please let us know by forwarding this message to <a href="mailto:support@coffix.co.nz" style="color:#1a73e8;text-decoration:underline;">support@coffix.co.nz</a></p>
          <p style="margin:0;"><a href="https://www.coffix.co.nz/term-of-use-privacy" style="color:#1a73e8;text-decoration:none;">Terms of Use &amp; Privacy</a></p>
        </td>
      </tr>
    </table>
  </body>

  
</html>`;
}
